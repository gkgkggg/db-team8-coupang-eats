const fs = require('fs');
const path = require('path');
const express = require('express');
const pool = require('../db');
const { badRequest, notFound } = require('../errors');

const router = express.Router();

const VALID_ORDER_STATUSES = new Set(['preparing', 'delivering', 'completed', 'cancelled']);

function loadQueries() {
  const sqlPath = path.resolve(__dirname, '../../../db/queries/orders.sql');
  const text = fs.readFileSync(sqlPath, 'utf8');
  const blocks = text.split(/-- \[([a-zA-Z0-9_]+)\]/);
  const queries = {};
  for (let i = 1; i < blocks.length; i += 2) {
    queries[blocks[i].trim()] = blocks[i + 1].trim();
  }
  return queries;
}

const QUERIES = loadQueries();

function parsePositiveId(raw) {
  if (!/^\d+$/.test(String(raw))) return null;
  const num = Number(raw);
  return Number.isSafeInteger(num) && num > 0 ? num : null;
}

function isValidRating(rating) {
  return typeof rating === 'number' && Number.isInteger(rating) && rating >= 1 && rating <= 5;
}

function formatDateTime(value) {
  if (!value) return null;
  return value instanceof Date ? value.toISOString() : String(value);
}

function conflictError(message) {
  const err = new Error(message);
  err.status = 409;
  err.statusCode = 409;
  return err;
}

router.get('/users/:userId/orders', async (req, res, next) => {
  const userId = parsePositiveId(req.params.userId);
  if (!userId) {
    return next(badRequest('userId는 1 이상의 정수여야 합니다.'));
  }

  const { status } = req.query;
  if (status !== undefined && !VALID_ORDER_STATUSES.has(status)) {
    return next(badRequest('status는 preparing, delivering, completed, cancelled 중 하나여야 합니다.'));
  }

  try {
    const [users] = await pool.execute(QUERIES.check_user_exists, [userId]);
    if (users.length === 0) {
      return next(notFound('존재하지 않는 사용자입니다.'));
    }

    const [countRows] = await pool.execute(QUERIES.get_unwritten_review_count, [userId]);
    const unwrittenReviewCount = Number(countRows[0].unwrittenReviewCount || 0);

    const [rows] = status === undefined
      ? await pool.execute(QUERIES.get_user_orders_all, [userId])
      : await pool.execute(QUERIES.get_user_orders_by_status, [userId, status]);

    const orders = rows.map((r) => {
      const repMenu = r.representativeMenuName || '';
      const extraMenuCount = Number(r.extraMenuCount || 0);
      const menuSummary = extraMenuCount > 0 ? `${repMenu} 외 ${extraMenuCount}개` : repMenu;
      const hasReview = Boolean(r.hasReview);

      return {
        orderId: Number(r.OrderID),
        userId: Number(r.UserID),
        storeId: Number(r.StoreID),
        storeName: r.StoreName,
        storeImageUrl: r.StoreImageURL,
        orderedAt: formatDateTime(r.OrderedAt),
        orderStatus: r.OrderStatus,
        menuSummary,
        extraMenuCount,
        menuSubtotal: Number(r.menuSubtotal),
        deliveryFee: Number(r.DeliveryFee),
        discountAmount: Number(r.DiscountAmount),
        totalAmount: Number(r.totalAmount),
        reviewId: r.ReviewID !== null ? Number(r.ReviewID) : null,
        hasReview,
        canWriteReview: r.OrderStatus === 'completed' && !hasReview,
      };
    });

    return res.status(200).json({
      userId,
      statusFilter: status ?? null,
      unwrittenReviewCount,
      orderCount: orders.length,
      orders,
    });
  } catch (err) {
    return next(err);
  }
});

router.get('/orders/:orderId', async (req, res, next) => {
  const orderId = parsePositiveId(req.params.orderId);
  if (!orderId) {
    return next(badRequest('orderId는 1 이상의 정수여야 합니다.'));
  }

  try {
    const [headers] = await pool.execute(QUERIES.get_order_detail_header, [orderId]);
    if (headers.length === 0) {
      return next(notFound('존재하지 않는 주문입니다.'));
    }

    const header = headers[0];
    const [items] = await pool.execute(QUERIES.get_order_detail_items, [orderId]);
    const hasReview = Boolean(header.hasReview);

    return res.status(200).json({
      orderId: Number(header.OrderID),
      userId: Number(header.UserID),
      store: {
        storeId: Number(header.StoreID),
        storeName: header.StoreName,
        storePhone: header.StorePhone,
        storeAddress: header.StoreAddress,
        storeImageUrl: header.StoreImageURL,
      },
      orderedAt: formatDateTime(header.OrderedAt),
      orderStatus: header.OrderStatus,
      deliveryAddressText: header.DeliveryAddressText,
      items: items.map((it) => ({
        menuId: Number(it.MenuID),
        menuNameAtOrder: it.MenuNameAtOrder,
        currentMenuName: it.currentMenuName,
        menuImageUrl: it.MenuImageURL,
        isAvailable: Boolean(it.IsAvailable),
        quantity: Number(it.Quantity),
        unitPriceAtOrder: Number(it.UnitPriceAtOrder),
        itemSubtotal: Number(it.itemSubtotal),
      })),
      paymentSummary: {
        menuSubtotal: Number(header.menuSubtotal),
        deliveryFee: Number(header.DeliveryFee),
        discountAmount: Number(header.DiscountAmount),
        totalAmount: Number(header.totalAmount),
      },
      review: {
        reviewId: header.ReviewID !== null ? Number(header.ReviewID) : null,
        hasReview,
        canWriteReview: header.OrderStatus === 'completed' && !hasReview,
      },
    });
  } catch (err) {
    return next(err);
  }
});

router.get('/orders/:orderId/review', async (req, res, next) => {
  const orderId = parsePositiveId(req.params.orderId);
  if (!orderId) {
    return next(badRequest('orderId는 1 이상의 정수여야 합니다.'));
  }

  try {
    const [rows] = await pool.execute(QUERIES.get_review_by_order_id, [orderId]);
    if (rows.length === 0) {
      return next(notFound('해당 주문 또는 작성된 리뷰가 존재하지 않습니다.'));
    }

    const review = rows[0];
    return res.status(200).json({
      reviewId: Number(review.ReviewID),
      orderId: Number(review.OrderID),
      userId: Number(review.UserID),
      storeId: Number(review.StoreID),
      rating: Number(review.Rating),
      content: review.Content,
      createdAt: formatDateTime(review.CreatedAt),
    });
  } catch (err) {
    return next(err);
  }
});

router.post('/orders/:orderId/review', async (req, res, next) => {
  const orderId = parsePositiveId(req.params.orderId);
  if (!orderId) {
    return next(badRequest('orderId는 1 이상의 정수여야 합니다.'));
  }

  const { rating, content = null } = req.body || {};
  if (!isValidRating(rating)) {
    return next(badRequest('rating은 1~5 사이의 정수여야 합니다.'));
  }
  if (content !== null && typeof content !== 'string') {
    return next(badRequest('content는 문자열이어야 합니다.'));
  }

  let conn;
  try {
    conn = await pool.getConnection();
    await conn.beginTransaction();

    const [orders] = await conn.execute(QUERIES.check_order_for_review, [orderId]);
    if (orders.length === 0) {
      await conn.rollback();
      return next(notFound('존재하지 않는 주문입니다.'));
    }

    const order = orders[0];
    if (order.OrderStatus !== 'completed') {
      await conn.rollback();
      return next(badRequest('완료(completed)된 주문만 리뷰를 작성할 수 있습니다.'));
    }
    if (order.existingReviewId !== null) {
      await conn.rollback();
      return next(conflictError('이미 해당 주문에 리뷰가 등록되어 있습니다.'));
    }

    const [insertResult] = await conn.execute(QUERIES.insert_review, [orderId, rating, content]);
    const newReviewId = insertResult.insertId;
    await conn.commit();

    const [createdRows] = await conn.execute(QUERIES.get_review_by_id, [newReviewId]);
    const created = createdRows[0];

    return res.status(201).json({
      reviewId: Number(created.ReviewID),
      orderId: Number(created.OrderID),
      userId: Number(created.UserID),
      storeId: Number(created.StoreID),
      rating: Number(created.Rating),
      content: created.Content,
      createdAt: formatDateTime(created.CreatedAt),
    });
  } catch (err) {
    if (conn) await conn.rollback();
    return next(err);
  } finally {
    if (conn) conn.release();
  }
});

router.put('/reviews/:reviewId', async (req, res, next) => {
  const reviewId = parsePositiveId(req.params.reviewId);
  if (!reviewId) {
    return next(badRequest('reviewId는 1 이상의 정수여야 합니다.'));
  }

  const { rating, content = null } = req.body || {};
  if (!isValidRating(rating)) {
    return next(badRequest('rating은 1~5 사이의 정수여야 합니다.'));
  }
  if (content !== null && typeof content !== 'string') {
    return next(badRequest('content는 문자열이어야 합니다.'));
  }

  let conn;
  try {
    conn = await pool.getConnection();
    await conn.beginTransaction();

    const [existingRows] = await conn.execute(QUERIES.get_review_by_id, [reviewId]);
    if (existingRows.length === 0) {
      await conn.rollback();
      return next(notFound('존재하지 않는 리뷰입니다.'));
    }

    await conn.execute(QUERIES.update_review, [rating, content, reviewId]);
    await conn.commit();

    const [updatedRows] = await conn.execute(QUERIES.get_review_by_id, [reviewId]);
    const updated = updatedRows[0];

    return res.status(200).json({
      reviewId: Number(updated.ReviewID),
      orderId: Number(updated.OrderID),
      userId: Number(updated.UserID),
      storeId: Number(updated.StoreID),
      rating: Number(updated.Rating),
      content: updated.Content,
      createdAt: formatDateTime(updated.CreatedAt),
    });
  } catch (err) {
    if (conn) await conn.rollback();
    return next(err);
  } finally {
    if (conn) conn.release();
  }
});

router.delete('/reviews/:reviewId', async (req, res, next) => {
  const reviewId = parsePositiveId(req.params.reviewId);
  if (!reviewId) {
    return next(badRequest('reviewId는 1 이상의 정수여야 합니다.'));
  }

  let conn;
  try {
    conn = await pool.getConnection();
    await conn.beginTransaction();

    const [existingRows] = await conn.execute(QUERIES.get_review_by_id, [reviewId]);
    if (existingRows.length === 0) {
      await conn.rollback();
      return next(notFound('존재하지 않는 리뷰입니다.'));
    }

    const existing = existingRows[0];
    const [helpfulResult] = await conn.execute(QUERIES.delete_review_helpful_by_review_id, [reviewId]);
    await conn.execute(QUERIES.delete_review, [reviewId]);
    await conn.commit();

    return res.status(200).json({
      deletedReviewId: reviewId,
      orderId: Number(existing.OrderID),
      deletedHelpfulCount: Number(helpfulResult.affectedRows || 0),
      message: '리뷰 및 연결된 ReviewHelpful 반응이 삭제되었습니다.',
    });
  } catch (err) {
    if (conn) await conn.rollback();
    return next(err);
  } finally {
    if (conn) conn.release();
  }
});

router.use((err, req, res, next) => {
  if (err && err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      error: {
        code: 'CONFLICT',
        message: '이미 해당 주문에 리뷰가 등록되어 있습니다.',
      },
    });
  }
  const status = err && (err.status || err.statusCode);
  if (status === 409) {
    return res.status(409).json({
      error: {
        code: 'CONFLICT',
        message: err.message,
      },
    });
  }
  return next(err);
});

module.exports = router;