var mongoose = require('mongoose');
var userSchema = mongoose.Schema;

userSchema = new userSchema({
  fname: {
    type: String,
    required: true
  },
  lname: {
    type: String,
    required: true
  },
  email: {
    type: String,
    unique: true,
    required: true
  },
  phoneNo: {
    type: String,
    unique: true,
    required: true
  },
  password: {
    type: String,
    required: true
  },
  state: {
    type: userSchema.Types.ObjectId,
    ref: 'States'
  },
  city: {
    type: userSchema.Types.ObjectId,
    ref: 'City'
  },
  pincode: {
    type: Number
  },
  userType: {
    type: Number,
    default: 1
  },
  isAdmin: {
    type: Boolean,
    default: false
  },
  updatedOn: {
    type: Date,
    default: Date.now()
  },
  createdOn: {
    type: Date
  }
});

module.exports = mongoose.model('users', userSchema);
