const express = require('express');
const router = express.Router();

// Mock data for reviews
let reviews = [];

// Get all reviews
router.get('/', (req, res) => {
    res.json(reviews);
});

// Get a review by ID
router.get('/:id', (req, res) => {
    const review = reviews.find(r => r.id === parseInt(req.params.id));
    if (!review) return res.status(404).send('Review not found');
    res.json(review);
});

// Create a new review
router.post('/', (req, res) => {
    const review = {
        id: reviews.length + 1,
        productId: req.body.productId,
        userId: req.body.userId,
        rating: req.body.rating,
        comment: req.body.comment
    };
    reviews.push(review);
    res.status(201).json(review);
});

// Update a review
router.put('/:id', (req, res) => {
    const review = reviews.find(r => r.id === parseInt(req.params.id));
    if (!review) return res.status(404).send('Review not found');

    review.rating = req.body.rating;
    review.comment = req.body.comment;
    res.json(review);
});

// Delete a review
router.delete('/:id', (req, res) => {
    const reviewIndex = reviews.findIndex(r => r.id === parseInt(req.params.id));
    if (reviewIndex === -1) return res.status(404).send('Review not found');

    reviews.splice(reviewIndex, 1);
    res.status(204).send();
});

module.exports = router;