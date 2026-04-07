const express = require('express');
const router = express.Router();

// Mock data for products
let products = [
    { id: 1, name: 'Product 1', price: 100 },
    { id: 2, name: 'Product 2', price: 200 },
    { id: 3, name: 'Product 3', price: 300 },
];

// Get all products
router.get('/', (req, res) => {
    res.json(products);
});

// Get a single product by ID
router.get('/:id', (req, res) => {
    const product = products.find(p => p.id === parseInt(req.params.id));
    if (!product) return res.status(404).send('Product not found');
    res.json(product);
});

// Create a new product
router.post('/', (req, res) => {
    const { name, price } = req.body;
    const newProduct = {
        id: products.length + 1,
        name,
        price,
    };
    products.push(newProduct);
    res.status(201).json(newProduct);
});

// Update a product
router.put('/:id', (req, res) => {
    const product = products.find(p => p.id === parseInt(req.params.id));
    if (!product) return res.status(404).send('Product not found');

    const { name, price } = req.body;
    product.name = name;
    product.price = price;
    res.json(product);
});

// Delete a product
router.delete('/:id', (req, res) => {
    const productIndex = products.findIndex(p => p.id === parseInt(req.params.id));
    if (productIndex === -1) return res.status(404).send('Product not found');

    products.splice(productIndex, 1);
    res.status(204).send();
});

module.exports = router;