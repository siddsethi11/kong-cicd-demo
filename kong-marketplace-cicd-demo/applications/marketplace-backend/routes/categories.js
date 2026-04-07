const express = require('express');
const router = express.Router();

// Mock data for categories
const categories = [
    { id: 1, name: 'Electronics' },
    { id: 2, name: 'Books' },
    { id: 3, name: 'Clothing' },
];

// Get all categories
router.get('/', (req, res) => {
    res.json(categories);
});

// Get a category by ID
router.get('/:id', (req, res) => {
    const category = categories.find(cat => cat.id === parseInt(req.params.id));
    if (!category) return res.status(404).send('Category not found');
    res.json(category);
});

// Create a new category
router.post('/', (req, res) => {
    const newCategory = {
        id: categories.length + 1,
        name: req.body.name,
    };
    categories.push(newCategory);
    res.status(201).json(newCategory);
});

// Update a category
router.put('/:id', (req, res) => {
    const category = categories.find(cat => cat.id === parseInt(req.params.id));
    if (!category) return res.status(404).send('Category not found');

    category.name = req.body.name;
    res.json(category);
});

// Delete a category
router.delete('/:id', (req, res) => {
    const categoryIndex = categories.findIndex(cat => cat.id === parseInt(req.params.id));
    if (categoryIndex === -1) return res.status(404).send('Category not found');

    categories.splice(categoryIndex, 1);
    res.status(204).send();
});

module.exports = router;