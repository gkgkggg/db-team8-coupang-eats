"""Render exact, editable SVG and PNG ERDs from the Markdown column dictionary.

Requires Pillow and Windows Malgun Gothic fonts. Does not connect to MySQL.
"""
from __future__ import annotations

import html
import json
import math
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
REGULAR = Path('C:/Windows/Fonts/malgun.ttf')
BOLD = Path('C:/Windows/Fonts/malgunbd.ttf')
BG = '#252525'
TEXT = '#eeeeee'
MUTED = '#b8b8bc'
CYAN = '#7ed4dc'
PINK = '#d9a0b4'
GOLD = '#edc955'
W, TITLE_H, HEAD_H, ROW_H = 1120, 54, 36, 42
WIDTHS = [40, 170, 300, 90, 230, 130, 160]
FONT_CACHE = {}

def font(size, bold=False):
    key = size, bold
    if key not in FONT_CACHE:
        FONT_CACHE[key] = ImageFont.truetype(str(BOLD if bold else REGULAR), size)
    return FONT_CACHE[key]

def read_tables():
    text = (ROOT / 'docs/db-column-dictionary.md').read_text(encoding='utf-8')
    result = {}
    for name, korean, body in re.findall(r'^### (\w+) — ([^\n]+)\n(.*?)(?=^### |^## |\Z)', text, re.M | re.S):
        rows = []
        for line in body.splitlines():
            if line.startswith('| `'):
                cells = [x.strip().strip('`') for x in line.strip().strip('|').split('|')]
                assert len(cells) == 5, (name, cells)
                rows.append(dict(zip(['name', 'type', 'key', 'nullable', 'description'], cells)))
        result[name] = {'name': name, 'korean': korean, 'rows': rows}
    assert len(result) == 11
    assert sum(len(t['rows']) for t in result.values()) == 57
    return result

TABLES = read_tables()
KOREAN = {
 'UserID':'사용자 ID','UserName':'사용자명','UserPhone':'전화번호','CreatedAt':'생성 시각',
 'AddressID':'주소 ID','AddressLabel':'주소 별칭','PostalCode':'우편번호','AddressLine1':'기본 주소',
 'AddressLine2':'상세 주소','IsDefault':'기본 주소 여부','CategoryID':'카테고리 ID',
 'CategoryName':'카테고리명','CategoryImageURL':'카테고리 이미지','DisplayOrder':'표시 순서',
 'StoreID':'가게 ID','StoreName':'가게명','StorePhone':'가게 전화번호','StoreAddress':'가게 주소',
 'StoreImageURL':'가게 대표 이미지','MinimumOrderAmount':'최소 주문 금액','DeliveryFee':'배달비',
 'EstimatedDeliveryMinutes':'기본 예상 분','IsOpen':'주문 가능 여부','MenuID':'메뉴 ID',
 'MenuName':'현재 메뉴명','CurrentPrice':'현재 가격','MenuImageURL':'메뉴 이미지',
 'IsAvailable':'판매 가능 여부','OrderID':'주문 ID','OrderedAt':'주문 시각',
 'OrderStatus':'주문 상태','DeliveryAddressText':'주문 당시 주소','DiscountAmount':'할인액',
 'Quantity':'수량','UnitPriceAtOrder':'주문 당시 단가','MenuNameAtOrder':'주문 당시 메뉴명',
 'ReviewID':'리뷰 ID','Rating':'별점','Content':'리뷰 내용'
}
DEFAULTS = {'IsDefault':'FALSE','DisplayOrder':'0','IsOpen':'TRUE','IsAvailable':'TRUE','DiscountAmount':'0'}

class Canvas:
    def __init__(self, width, height):
        self.width, self.height = width, height
        self.image = Image.new('RGB', (width, height), BG)
        self.draw = ImageDraw.Draw(self.image)
        self.svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
                    f'<rect width="100%" height="100%" fill="{BG}"/>']
        self.text_count = 0

    def rect(self, box, fill, outline=None, width=1):
        x0,y0,x1,y1=box
        self.draw.rectangle(box, fill=fill, outline=outline, width=width)
        self.svg.append(f'<rect x="{x0}" y="{y0}" width="{x1-x0}" height="{y1-y0}" fill="{fill}" stroke="{outline or fill}" stroke-width="{width}"/>')

    def line(self, points, color, width=3, dashed=False):
        if dashed:
            for a,b in zip(points,points[1:]):
                length=math.dist(a,b)
                if not length: continue
                for start in range(0, math.ceil(length), 25):
                    end=min(start+15,length)
                    p=(a[0]+(b[0]-a[0])*start/length,a[1]+(b[1]-a[1])*start/length)
                    q=(a[0]+(b[0]-a[0])*end/length,a[1]+(b[1]-a[1])*end/length)
                    self.draw.line([p,q], fill=color, width=width)
        else:
            self.draw.line(points, fill=color, width=width, joint='curve')
        pts=' '.join(f'{x},{y}' for x,y in points)
        dash=' stroke-dasharray="15 10"' if dashed else ''
        self.svg.append(f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linejoin="round"{dash}/>')

    def circle(self,x,y,r,color,width=3,fill=BG):
        self.draw.ellipse((x-r,y-r,x+r,y+r),fill=fill,outline=color,width=width)
        self.svg.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{color}" stroke-width="{width}"/>')

    def text(self,x,y,value,size=20,color=TEXT,bold=False,max_width=None,align='left'):
        value=str(value)
        while max_width and font(size,bold).getlength(value)>max_width and size>15:
            size-=1
        if max_width:
            assert font(size,bold).getlength(value)<=max_width,(value,max_width,size)
        anchor={'left':'lm','right':'rm','center':'mm'}[align]
        self.draw.text((x,y),value,font=font(size,bold),fill=color,anchor=anchor)
        svg_anchor={'left':'start','right':'end','center':'middle'}[align]
        weight='700' if bold else '400'
        self.svg.append(f'<text x="{x}" y="{y}" fill="{color}" font-family="Malgun Gothic, Apple SD Gothic Neo, Noto Sans KR, sans-serif" font-size="{size}" font-weight="{weight}" text-anchor="{svg_anchor}" dominant-baseline="central">{html.escape(value)}</text>')
        self.text_count += 1

    def save(self, stem):
        self.image.save(OUT/f'{stem}.png',optimize=True)
        (OUT/f'{stem}.svg').write_text('\n'.join(self.svg+['</svg>']),encoding='utf-8')

def height(name):
    return TITLE_H+HEAD_H+len(TABLES[name]['rows'])*ROW_H

def port(nodes, name, column, side):
    x,y=nodes[name]
    row=next(i for i,r in enumerate(TABLES[name]['rows']) if r['name']==column)
    return (x if side=='L' else x+W,y+TITLE_H+HEAD_H+(row+.5)*ROW_H)

def key_icon(c,x,y,color):
    c.circle(x+10,y,6,color,2,fill=BG)
    c.line([(x+16,y),(x+29,y)],color,3)
    c.line([(x+23,y),(x+23,y+6)],color,3)
    c.line([(x+29,y),(x+29,y+5)],color,3)

def table(c,name,pos):
    x,y=pos; t=TABLES[name]
    c.rect((x-3,y-3,x+W+3,y+height(name)+3),'#101010')
    c.rect((x,y,x+W,y+TITLE_H),'#151515')
    c.text(x+14,y+TITLE_H/2,t['korean'],28,bold=True,max_width=680)
    c.text(x+W-14,y+TITLE_H/2,name,26,bold=True,align='right',max_width=380)
    headers=['','논리명','컬럼명','키','자료형(MySQL)','NULL','기본값(안)']
    c.rect((x,y+TITLE_H,x+W,y+TITLE_H+HEAD_H),'#333337')
    offset=x
    for label,w in zip(headers,WIDTHS):
        c.text(offset+10,y+TITLE_H+HEAD_H/2,label,18,color='#ccccd0',max_width=w-16)
        offset+=w
    for i,r in enumerate(t['rows']):
        yy=y+TITLE_H+HEAD_H+i*ROW_H
        pk='PK' in r['key']; fk='FK' in r['key']; uq='UNIQUE' in r['key']
        color=CYAN if pk and fk else GOLD if pk else PINK if fk else MUTED
        fill='#193c40' if pk and fk else '#49351e' if pk else '#332b32' if fk else '#2a2a2d' if i%2 else '#2e2e31'
        c.rect((x,yy,x+W,yy+ROW_H),fill,outline='#161618',width=2)
        if pk or fk: key_icon(c,x+3,yy+ROW_H/2,color)
        key='PK/FK' if pk and fk else 'PK' if pk else 'FK/UQ' if fk and uq else 'FK' if fk else 'UQ' if uq else '—'
        default=DEFAULTS.get(r['name'],'미정' if pk and not fk or r['name']=='CreatedAt' else '—')
        values=['',KOREAN[r['name']],r['name'],key,r['type'],'NULL' if r['nullable']=='Y' else 'NOT NULL',default]
        offset=x
        for j,(value,w) in enumerate(zip(values,WIDTHS)):
            if j: c.line([(offset,yy),(offset,yy+ROW_H)],'#171719',2)
            c.text(offset+10,yy+ROW_H/2,value,20,color=color if j==3 else MUTED if j==6 or r['nullable']=='Y' and j==5 else TEXT,bold=pk and j in (1,2,3),max_width=w-18)
            offset+=w

def marker(c,p,side,color,kind):
    dx=-1 if side=='L' else 1
    def at(d,n=0): return (p[0]+dx*d,p[1]+n)
    if kind=='one':
        for d in [14,23]: c.line([at(d,-11),at(d,11)],color,3)
    elif kind=='many':
        for n in [-12,0,12]: c.line([at(29),at(6,n)],color,3)
        c.circle(*at(44),7,color,3)
    else:
        c.line([at(18,-11),at(18,11)],color,3)
        c.circle(*at(39),7,color,3)

def make_edge(nodes,parent,child,fk,ps,cs,waypoints=(),label=None):
    parent_pk=next(r['name'] for r in TABLES[parent]['rows'] if r['key']=='PK')
    row=next(r for r in TABLES[child]['rows'] if r['name']==fk)
    assert f'FK → {parent}.{parent_pk}' in row['key']
    p=port(nodes,parent,parent_pk,ps); q=port(nodes,child,fk,cs)
    mid=[(a(p,q) if callable(a) else a,b(p,q) if callable(b) else b) for a,b in waypoints]
    points=[p]+mid+[q]
    assert all(a[0]==b[0] or a[1]==b[1] for a,b in zip(points,points[1:])),(parent,child,points)
    return {'parent':parent,'child':child,'fk':fk,'ps':ps,'cs':cs,'points':points,'identifying':'PK' in row['key'],'unique':'UNIQUE' in row['key'],'label':label}

def rail(x): return [(x,lambda p,q:p[1]),(x,lambda p,q:q[1])]

def legend(c,x,y,available):
    c.rect((x,y,x+available,y+150),'#202023',outline='#55555a',width=1)
    c.text(x+22,y+28,'범례 · 기본키(Primary Key) / 외래키(Foreign Key)',24,bold=True)
    entries=[(GOLD,'PK'),(PINK,'FK'),(CYAN,'PK/FK: 복합키 구성')]
    for i,(color,label) in enumerate(entries):
        xx=x+26+i*420; key_icon(c,xx,y+67,color); c.text(xx+44,y+67,label,22,color=color)
    c.line([(x+1450,y+67),(x+1570,y+67)],CYAN,4)
    c.text(x+1590,y+67,'실선: 식별 관계',22)
    c.line([(x+2150,y+67),(x+2270,y+67)],PINK,4,True)
    c.text(x+2290,y+67,'점선: 비식별 관계',22)
    c.text(x+24,y+111,'1 : 0..N = 일대다   ·   1 : 0..1 = 주문당 리뷰 최대 1개   ·   UQ = 유일 제약   ·   기본값·ID 자동 생성은 DDL 작성 시 확정',22,max_width=available-48)

def render(stem,title,nodes,width,height_px,edges,legend_y):
    c=Canvas(width,height_px)
    count=sum(len(TABLES[n]['rows']) for n in nodes)
    c.text(80,68,title,42,bold=True)
    c.text(82,122,f'3NF 설계안  |  {len(nodes)}개 테이블 · {count}개 컬럼 · {len(edges)}개 FK 관계  |  컬럼 사전과 동일한 이름·자료형',24,color=MUTED)
    previous=[]
    for e in edges:
        # Unrelated lines may cross, but must never merge into a false relationship.
        for old in previous:
            if old['parent']==e['parent']:
                continue
            for a,b in zip(e['points'],e['points'][1:]):
                for p,q in zip(old['points'],old['points'][1:]):
                    h=a[1]==b[1]; oh=p[1]==q[1]
                    if h==oh:
                        same_line=a[1]==p[1] if h else a[0]==p[0]
                        first=sorted((a[0],b[0]) if h else (a[1],b[1]))
                        second=sorted((p[0],q[0]) if h else (p[1],q[1]))
                        overlap=min(first[1],second[1])-max(first[0],second[0])
                        assert not (same_line and overlap>0),(stem,e['parent'],e['child'],old['parent'],old['child'])
                    else:
                        ha,hb,va,vb=(a,b,p,q) if h else (p,q,a,b)
                        xx,yy=va[0],ha[1]
                        if min(ha[0],hb[0])<xx<max(ha[0],hb[0]) and min(va[1],vb[1])<yy<max(va[1],vb[1]):
                            c.circle(xx,yy,9,BG,1,BG)
        c.line(e['points'],CYAN if e['identifying'] else PINK,4,not e['identifying'])
        previous.append(e)
    for name,pos in nodes.items(): table(c,name,pos)
    for e in edges:
        color=CYAN if e['identifying'] else PINK
        marker(c,e['points'][0],e['ps'],color,'one')
        marker(c,e['points'][-1],e['cs'],color,'optional_one' if e['unique'] else 'many')
        label='1 : 0..1' if e['unique'] else '1 : 0..N'
        if e['label']:
            x,y=e['label']
        else:
            a,b=max(zip(e['points'],e['points'][1:]),key=lambda ab:math.dist(*ab))
            x,y=(a[0]+b[0])/2,(a[1]+b[1])/2
        ww=font(21,True).getlength(label)+20
        c.rect((x-ww/2,y-18,x+ww/2,y+18),BG)
        c.text(x,y,label,21,color=color,bold=True,align='center')
    legend(c,80,legend_y,width-160)
    c.save(stem)
    return {'file':stem,'tables':len(nodes),'columns':count,'fk_relations':len(edges),'size':[width,height_px]}

def main():
    reports=[]
    n={'Users':(280,230),'Favorites':(1660,230),'Stores':(3040,230),'StoreCategories':(4420,230),'Addresses':(280,850),'Orders':(1660,850),'Menus':(3040,850),'Categories':(4420,850),'ReviewHelpful':(280,1510),'Reviews':(1660,1510),'OrderItems':(3040,1510)}
    e=[make_edge(n,'Users','Favorites','UserID','R','L'),
       make_edge(n,'Stores','Favorites','StoreID','L','R',rail(2900)),
       make_edge(n,'Stores','StoreCategories','StoreID','R','L'),
       make_edge(n,'Categories','StoreCategories','CategoryID','R','R',rail(5630),(5630,690)),
       make_edge(n,'Users','Addresses','UserID','L','L',rail(205),(205,730)),
       make_edge(n,'Users','ReviewHelpful','UserID','L','L',rail(130),(130,1380)),
       make_edge(n,'Users','Orders','UserID','R','L',rail(1510),(1510,700)),
       make_edge(n,'Stores','Orders','StoreID','L','R',rail(2860),(2860,590)),
       make_edge(n,'Stores','Menus','StoreID','L','L',rail(2950),(2950,760)),
       make_edge(n,'Orders','OrderItems','OrderID','R','L',rail(2905),(2905,1380)),
       make_edge(n,'Menus','OrderItems','MenuID','R','R',rail(4300),(4300,1380)),
       make_edge(n,'Orders','Reviews','OrderID','L','L',rail(1550),(1550,1380)),
       make_edge(n,'Reviews','ReviewHelpful','ReviewID','L','R',rail(1510))]
    assert len(e)==13
    declared={(m[1],t['name'],r['name']) for t in TABLES.values() for r in t['rows'] if (m:=re.search(r'FK → (\w+)\.(\w+)',r['key']))}
    assert declared=={(x['parent'],x['child'],x['fk']) for x in e}
    reports.append(render('db8-erd-full','쿠팡이츠 · 세 View 전체 ERD',n,5740,2220,e,2010))

    n={'Users':(240,220),'Addresses':(240,740),'Stores':(3020,220),'StoreCategories':(1640,740),'Categories':(3020,940)}
    e=[make_edge(n,'Users','Addresses','UserID','L','L',rail(110),(110,590)),
       make_edge(n,'Stores','StoreCategories','StoreID','L','R',rail(2840),(2840,620)),
       make_edge(n,'Categories','StoreCategories','CategoryID','L','R',rail(2920),(2920,1010))]
    reports.append(render('db8-erd-home','View 1 · 홈 — 전지우',n,4380,1510,e,1290))

    n={'Users':(240,220),'Favorites':(1620,220),'Stores':(3000,220),'ReviewHelpful':(240,840),'Reviews':(1620,840),'Orders':(3000,840),'Addresses':(240,1460)}
    e=[make_edge(n,'Users','Favorites','UserID','R','L'),
       make_edge(n,'Stores','Favorites','StoreID','L','R',rail(2860)),
       make_edge(n,'Users','ReviewHelpful','UserID','L','L',rail(140),(140,700)),
       make_edge(n,'Users','Addresses','UserID','L','L',rail(70),(70,1350)),
       make_edge(n,'Users','Orders','UserID','R','L',[(1490,lambda p,q:p[1]),(1490,760),(2900,760),(2900,lambda p,q:q[1])],(2200,760)),
       make_edge(n,'Stores','Orders','StoreID','R','R',rail(4250),(4250,750)),
       make_edge(n,'Orders','Reviews','OrderID','L','R',rail(2860)),
       make_edge(n,'Reviews','ReviewHelpful','ReviewID','L','R',rail(1490))]
    reports.append(render('db8-erd-my-page','View 2 · 마이이츠·즐겨찾기 — 홍승민',n,4380,2240,e,2020))

    n={'Users':(240,220),'Orders':(1620,220),'Stores':(3000,220),'Reviews':(240,840),'OrderItems':(1620,840),'Menus':(3000,840)}
    e=[make_edge(n,'Users','Orders','UserID','R','L',rail(1490)),
       make_edge(n,'Stores','Orders','StoreID','L','R',rail(2860)),
       make_edge(n,'Stores','Menus','StoreID','R','R',rail(4250),(4250,750)),
       make_edge(n,'Orders','OrderItems','OrderID','L','L',rail(1510),(1510,590)),
       make_edge(n,'Orders','Reviews','OrderID','L','R',rail(1550),(1550,710)),
       make_edge(n,'Menus','OrderItems','MenuID','L','R',rail(2860))]
    reports.append(render('db8-erd-orders','View 3 · 주문내역 — 심동진',n,4380,1510,e,1290))
    print(json.dumps({'figures':reports,'validated_table_count':11,'validated_column_count':57,'validated_fk_count':13},ensure_ascii=False))

if __name__=='__main__':
    main()
