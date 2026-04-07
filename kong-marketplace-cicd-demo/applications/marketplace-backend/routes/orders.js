const express = require('express');
const router = express.Router();
const { createOrder, getOrder, updateOrder, deleteOrder, getAllOrders } = require('../controllers/orderController');

// Route to create a new order
router.post('/', createOrder);

// Route to get a specific order by ID
router.get('/:id', getOrder);

// Route to update an existing order by ID
router.put('/:id', updateOrder);

// Route to delete an order by ID
router.delete('/:id', deleteOrder);

// Route to get all orders
router.get('/', getAllOrders);

module.exports = router;