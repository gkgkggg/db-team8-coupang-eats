const express = require('express');
const pool = require('../db');
const { badRequest, notFound, parseId } = require('../errors');

const router = express.Router();

const RATING_SUBQUERY = `
  SELECT o.StoreID, ROUND(AVG(rv.Rating), 1) AS AvgRating, COUNT(*) AS ReviewCount
  FROM Reviews rv
  JOIN Orders o ON o.OrderID = rv.OrderID`;

const SORTS = {
  name: 's.StoreName, s.StoreID',
  deliveryFee: 's.DeliveryFee, s.StoreID',
  rating: 'r.AvgRating IS NULL, r.AvgRating DESC, ReviewCount DESC, s.StoreID',
};

const toStoreSummary = (row) => ({
  storeId: row.StoreID,
  storeName: row.StoreName,
  storeImageUrl: row.StoreImageURL,
  deliveryFee: row.DeliveryFee,
  minimumOrderAmount: row.MinimumOrderAmount,
  estimatedDeliveryMinutes: row.EstimatedDeliveryMinutes,
  isOpen: row.IsOpen === 1,
  rating: row.AvgRating,
  reviewCount: Number(row.ReviewCount),
});

const escapeLike = (s) => s.replace(/[\\%_]/g, (c) => '\\' + c);

async function storeExists(storeId) {
  const [rows] = await pool.execute('SELECT StoreID FROM Stores WHERE StoreID = ?', [storeId]);
  return rows.length > 0;
}

function singleQueryValues(query, names) {
  for (const name of names) {
    const v = query[name];
    if (v !== undefined && typeof v !== 'string') {
      throw badRequest(`${name}는 한 번만 전달해야 합니다.`);
    }
  }
}

function parseStoreFilters(query) {
  singleQueryValues(query, ['categoryId', 'keyword', 'sort']);

  const categoryId = query.categoryId === undefined || query.categoryId === ''
    ? null
    : parseId(query.categoryId, 'categoryId');

  const keyword = query.keyword === undefined ? null : query.keyword.trim() || null;
  if (keyword !== null && keyword.length > 100) {
    throw badRequest('keyword는 100자 이하여야 합니다.');
  }

  const sort = query.sort === undefined || query.sort === '' ? 'name' : query.sort;
  if (!Object.hasOwn(SORTS, sort)) {
    throw badRequest('sort는 name, deliveryFee, rating 중 하나여야 합니다.');
  }

  return { categoryId, keyword, sort };
}

async function findCategories() {
  const [rows] = await pool.execute(
    `SELECT CategoryID, CategoryName, CategoryImageURL, DisplayOrder
     FROM Categories
     ORDER BY DisplayOrder, CategoryID`
  );
  return rows.map((r) => ({
    categoryId: r.CategoryID,
    categoryName: r.CategoryName,
    categoryImageUrl: r.CategoryImageURL,
    displayOrder: r.DisplayOrder,
  }));
}

async function findStores({ categoryId, keyword, sort }) {
  if (categoryId !== null) {
    const [cats] = await pool.execute('SELECT CategoryID FROM Categories WHERE CategoryID = ?', [categoryId]);
    if (cats.length === 0) throw notFound(`categoryId ${categoryId} 카테고리가 없습니다.`);
  }

  const likeKeyword = keyword === null ? null : escapeLike(keyword);
  const [rows] = await pool.execute(
    `SELECT s.StoreID, s.StoreName, s.StoreImageURL, s.DeliveryFee, s.MinimumOrderAmount,
            s.EstimatedDeliveryMinutes, s.IsOpen,
            r.AvgRating, COALESCE(r.ReviewCount, 0) AS ReviewCount
     FROM Stores s
     LEFT JOIN (${RATING_SUBQUERY} GROUP BY o.StoreID) r ON r.StoreID = s.StoreID
     WHERE (? IS NULL
            OR s.StoreID IN (SELECT sc.StoreID FROM StoreCategories sc WHERE sc.CategoryID = ?))
       AND (? IS NULL OR s.StoreName LIKE CONCAT('%', ?, '%'))
     ORDER BY ${SORTS[sort]}`,
    [categoryId, categoryId, likeKeyword, likeKeyword]
  );
  return rows.map(toStoreSummary);
}

async function findDefaultAddress(userId) {
  const [users] = await pool.execute('SELECT UserID FROM Users WHERE UserID = ?', [userId]);
  if (users.length === 0) throw notFound(`userId ${userId} 사용자가 없습니다.`);

  const [rows] = await pool.execute(
    `SELECT AddressID, AddressLabel, PostalCode, AddressLine1, AddressLine2
     FROM Addresses
     WHERE UserID = ? AND IsDefault = TRUE`,
    [userId]
  );
  if (rows.length === 0) return null;
  const a = rows[0];
  return {
    addressId: a.AddressID,
    addressLabel: a.AddressLabel,
    postalCode: a.PostalCode,
    addressLine1: a.AddressLine1,
    addressLine2: a.AddressLine2,
  };
}

router.get('/home', async (req, res) => {
  singleQueryValues(req.query, ['userId']);
  if (req.query.userId === undefined || req.query.userId === '') {
    throw badRequest('userId는 필수입니다.');
  }
  const userId = parseId(req.query.userId, 'userId');
  const filters = parseStoreFilters(req.query);

  const address = await findDefaultAddress(userId);
  const categories = await findCategories();
  const stores = await findStores(filters);
  res.json({ address, categories, stores });
});

router.get('/categories', async (req, res) => {
  res.json(await findCategories());
});

router.get('/stores', async (req, res) => {
  res.json(await findStores(parseStoreFilters(req.query)));
});

router.get('/stores/:storeId', async (req, res) => {
  const storeId = parseId(req.params.storeId, 'storeId');
  const [rows] = await pool.execute(
    `SELECT s.StoreID, s.StoreName, s.StorePhone, s.StoreAddress, s.StoreImageURL,
            s.DeliveryFee, s.MinimumOrderAmount, s.EstimatedDeliveryMinutes, s.IsOpen,
            r.AvgRating, COALESCE(r.ReviewCount, 0) AS ReviewCount
     FROM Stores s
     LEFT JOIN (${RATING_SUBQUERY} WHERE o.StoreID = ? GROUP BY o.StoreID) r ON r.StoreID = s.StoreID
     WHERE s.StoreID = ?`,
    [storeId, storeId]
  );
  if (rows.length === 0) throw notFound(`storeId ${storeId} 가게가 없습니다.`);

  const row = rows[0];
  res.json({
    ...toStoreSummary(row),
    storePhone: row.StorePhone,
    storeAddress: row.StoreAddress,
  });
});

router.get('/stores/:storeId/menus', async (req, res) => {
  const storeId = parseId(req.params.storeId, 'storeId');
  if (!(await storeExists(storeId))) throw notFound(`storeId ${storeId} 가게가 없습니다.`);

  const [rows] = await pool.execute(
    `SELECT MenuID, MenuName, CurrentPrice, MenuImageURL, IsAvailable
     FROM Menus
     WHERE StoreID = ?
     ORDER BY MenuID`,
    [storeId]
  );
  res.json(rows.map((r) => ({
    menuId: r.MenuID,
    menuName: r.MenuName,
    currentPrice: r.CurrentPrice,
    menuImageUrl: r.MenuImageURL,
    isAvailable: r.IsAvailable === 1,
  })));
});

module.exports = router;
