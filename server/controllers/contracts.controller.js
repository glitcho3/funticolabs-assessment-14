const {
  getContractInfoByAddress
} = require('../services/contracts');

async function getAll(req, res) {
  // not implemented yet, but must exist
  res.status(200).json([]);
}

async function getCount(req, res) {
  res.status(200).json({ count: 0 });
}

async function getByIndex(req, res) {
  res.status(404).json({ error: 'Not implemented' });
}

async function getByAddress(req, res) {
  try {
    const { address } = req.params;

    const contract = getContractInfoByAddress(address);

    if (!contract) {
      return res.status(404).json({ error: 'Contract not found' });
    }

    res.status(200).json({
      instance: {
        address: contract.address,
        methods: contract.methods
      },
      transactionHash: contract.transactionHash
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
}

module.exports = {
  getAll,
  getCount,
  getByIndex,
  getByAddress
};

