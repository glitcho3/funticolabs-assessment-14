const express = require('express');
const router = express.Router();

const contractsController = require('../controllers/contracts.controller');

router.get('/', contractsController.getAll);

router.get('/count', contractsController.getCount);

router.get('/:index', contractsController.getByIndex);

router.get('/by-address/:address', contractsController.getByAddress);

module.exports = router;

