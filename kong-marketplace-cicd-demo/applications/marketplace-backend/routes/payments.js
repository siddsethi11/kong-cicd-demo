const express = require('express');
const router = express.Router();
const { processPayment } = require('../controllers/paymentsController');

// Route to handle payment processing
router.post('/', async (req, res, next) => {
    try {
        const paymentData = req.body;
        const result = await processPayment(paymentData);
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
});

// Route to retrieve payment status
router.get('/:paymentId', async (req, res, next) => {
    try {
        const paymentId = req.params.paymentId;
        const paymentStatus = await getPaymentStatus(paymentId);
        res.status(200).json(paymentStatus);
    } catch (error) {
        next(error);
    }
});

module.exports = router;