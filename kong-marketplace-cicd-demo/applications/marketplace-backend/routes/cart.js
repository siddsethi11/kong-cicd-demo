const express = require('express');
const router = express.Router();

// Mock cart data
let cart = [];

// Get all items in the cart
router.get('/', (req, res) => {
    res.json(cart);
});

// Add an item to the cart
router.post('/', (req, res) => {
    const item = req.body;
    cart.push(item);
    res.status(201).json(item);
});

// Remove an item from the cart
router.delete('/:id', (req, res) => {
    const { id } = req.params;
    cart = cart.filter(item => item.id !== id);
    res.status(204).send();
});

// Clear the cart
router.delete('/', (req, res) => {
    cart = [];
    res.status(204).send();
});

module.exports = router;