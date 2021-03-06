/**
 * @fileoverview
 * @enhanceable
 * @suppress {messageConventions} JS Compiler reports an error if a variable or
 *     field starts with 'MSG_' and isn't a translatable message.
 * @public
 */
// GENERATED CODE -- DO NOT EDIT!

var jspb = require('google-protobuf');
var goog = jspb;
var global = Function('return this')();

var common_pb = require('./common_pb.js');
goog.exportSymbol('proto.base.PublisherConfig', null, global);
goog.exportSymbol('proto.base.Signal', null, global);
goog.exportSymbol('proto.base.SignalIds', null, global);
goog.exportSymbol('proto.base.Signals', null, global);
goog.exportSymbol('proto.base.SubscriberConfig', null, global);

/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.base.SubscriberConfig = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, null);
};
goog.inherits(proto.base.SubscriberConfig, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  proto.base.SubscriberConfig.displayName = 'proto.base.SubscriberConfig';
}


if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto suitable for use in Soy templates.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     com.google.apps.jspb.JsClassTemplate.JS_RESERVED_WORDS.
 * @param {boolean=} opt_includeInstance Whether to include the JSPB instance
 *     for transitional soy proto support: http://goto/soy-param-migration
 * @return {!Object}
 */
proto.base.SubscriberConfig.prototype.toObject = function(opt_includeInstance) {
  return proto.base.SubscriberConfig.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Whether to include the JSPB
 *     instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.base.SubscriberConfig} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.SubscriberConfig.toObject = function(includeInstance, msg) {
  var f, obj = {
    clientid: (f = msg.getClientid()) && common_pb.ClientId.toObject(includeInstance, f),
    signals: (f = msg.getSignals()) && proto.base.SignalIds.toObject(includeInstance, f),
    onchange: jspb.Message.getFieldWithDefault(msg, 3, false)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.base.SubscriberConfig}
 */
proto.base.SubscriberConfig.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.base.SubscriberConfig;
  return proto.base.SubscriberConfig.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.base.SubscriberConfig} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.base.SubscriberConfig}
 */
proto.base.SubscriberConfig.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new common_pb.ClientId;
      reader.readMessage(value,common_pb.ClientId.deserializeBinaryFromReader);
      msg.setClientid(value);
      break;
    case 2:
      var value = new proto.base.SignalIds;
      reader.readMessage(value,proto.base.SignalIds.deserializeBinaryFromReader);
      msg.setSignals(value);
      break;
    case 3:
      var value = /** @type {boolean} */ (reader.readBool());
      msg.setOnchange(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.base.SubscriberConfig.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.base.SubscriberConfig.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.base.SubscriberConfig} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.SubscriberConfig.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getClientid();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      common_pb.ClientId.serializeBinaryToWriter
    );
  }
  f = message.getSignals();
  if (f != null) {
    writer.writeMessage(
      2,
      f,
      proto.base.SignalIds.serializeBinaryToWriter
    );
  }
  f = message.getOnchange();
  if (f) {
    writer.writeBool(
      3,
      f
    );
  }
};


/**
 * optional ClientId clientId = 1;
 * @return {?proto.base.ClientId}
 */
proto.base.SubscriberConfig.prototype.getClientid = function() {
  return /** @type{?proto.base.ClientId} */ (
    jspb.Message.getWrapperField(this, common_pb.ClientId, 1));
};


/** @param {?proto.base.ClientId|undefined} value */
proto.base.SubscriberConfig.prototype.setClientid = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


proto.base.SubscriberConfig.prototype.clearClientid = function() {
  this.setClientid(undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.SubscriberConfig.prototype.hasClientid = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional SignalIds signals = 2;
 * @return {?proto.base.SignalIds}
 */
proto.base.SubscriberConfig.prototype.getSignals = function() {
  return /** @type{?proto.base.SignalIds} */ (
    jspb.Message.getWrapperField(this, proto.base.SignalIds, 2));
};


/** @param {?proto.base.SignalIds|undefined} value */
proto.base.SubscriberConfig.prototype.setSignals = function(value) {
  jspb.Message.setWrapperField(this, 2, value);
};


proto.base.SubscriberConfig.prototype.clearSignals = function() {
  this.setSignals(undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.SubscriberConfig.prototype.hasSignals = function() {
  return jspb.Message.getField(this, 2) != null;
};


/**
 * optional bool onChange = 3;
 * Note that Boolean fields may be set to 0/1 when serialized from a Java server.
 * You should avoid comparisons like {@code val === true/false} in those cases.
 * @return {boolean}
 */
proto.base.SubscriberConfig.prototype.getOnchange = function() {
  return /** @type {boolean} */ (jspb.Message.getFieldWithDefault(this, 3, false));
};


/** @param {boolean} value */
proto.base.SubscriberConfig.prototype.setOnchange = function(value) {
  jspb.Message.setField(this, 3, value);
};



/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.base.SignalIds = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, proto.base.SignalIds.repeatedFields_, null);
};
goog.inherits(proto.base.SignalIds, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  proto.base.SignalIds.displayName = 'proto.base.SignalIds';
}
/**
 * List of repeated fields within this message type.
 * @private {!Array<number>}
 * @const
 */
proto.base.SignalIds.repeatedFields_ = [1];



if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto suitable for use in Soy templates.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     com.google.apps.jspb.JsClassTemplate.JS_RESERVED_WORDS.
 * @param {boolean=} opt_includeInstance Whether to include the JSPB instance
 *     for transitional soy proto support: http://goto/soy-param-migration
 * @return {!Object}
 */
proto.base.SignalIds.prototype.toObject = function(opt_includeInstance) {
  return proto.base.SignalIds.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Whether to include the JSPB
 *     instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.base.SignalIds} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.SignalIds.toObject = function(includeInstance, msg) {
  var f, obj = {
    signalidList: jspb.Message.toObjectList(msg.getSignalidList(),
    common_pb.SignalId.toObject, includeInstance)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.base.SignalIds}
 */
proto.base.SignalIds.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.base.SignalIds;
  return proto.base.SignalIds.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.base.SignalIds} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.base.SignalIds}
 */
proto.base.SignalIds.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new common_pb.SignalId;
      reader.readMessage(value,common_pb.SignalId.deserializeBinaryFromReader);
      msg.addSignalid(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.base.SignalIds.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.base.SignalIds.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.base.SignalIds} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.SignalIds.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getSignalidList();
  if (f.length > 0) {
    writer.writeRepeatedMessage(
      1,
      f,
      common_pb.SignalId.serializeBinaryToWriter
    );
  }
};


/**
 * repeated SignalId signalId = 1;
 * @return {!Array.<!proto.base.SignalId>}
 */
proto.base.SignalIds.prototype.getSignalidList = function() {
  return /** @type{!Array.<!proto.base.SignalId>} */ (
    jspb.Message.getRepeatedWrapperField(this, common_pb.SignalId, 1));
};


/** @param {!Array.<!proto.base.SignalId>} value */
proto.base.SignalIds.prototype.setSignalidList = function(value) {
  jspb.Message.setRepeatedWrapperField(this, 1, value);
};


/**
 * @param {!proto.base.SignalId=} opt_value
 * @param {number=} opt_index
 * @return {!proto.base.SignalId}
 */
proto.base.SignalIds.prototype.addSignalid = function(opt_value, opt_index) {
  return jspb.Message.addToRepeatedWrapperField(this, 1, opt_value, proto.base.SignalId, opt_index);
};


proto.base.SignalIds.prototype.clearSignalidList = function() {
  this.setSignalidList([]);
};



/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.base.Signals = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, proto.base.Signals.repeatedFields_, null);
};
goog.inherits(proto.base.Signals, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  proto.base.Signals.displayName = 'proto.base.Signals';
}
/**
 * List of repeated fields within this message type.
 * @private {!Array<number>}
 * @const
 */
proto.base.Signals.repeatedFields_ = [1];



if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto suitable for use in Soy templates.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     com.google.apps.jspb.JsClassTemplate.JS_RESERVED_WORDS.
 * @param {boolean=} opt_includeInstance Whether to include the JSPB instance
 *     for transitional soy proto support: http://goto/soy-param-migration
 * @return {!Object}
 */
proto.base.Signals.prototype.toObject = function(opt_includeInstance) {
  return proto.base.Signals.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Whether to include the JSPB
 *     instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.base.Signals} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.Signals.toObject = function(includeInstance, msg) {
  var f, obj = {
    signalList: jspb.Message.toObjectList(msg.getSignalList(),
    proto.base.Signal.toObject, includeInstance)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.base.Signals}
 */
proto.base.Signals.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.base.Signals;
  return proto.base.Signals.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.base.Signals} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.base.Signals}
 */
proto.base.Signals.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new proto.base.Signal;
      reader.readMessage(value,proto.base.Signal.deserializeBinaryFromReader);
      msg.addSignal(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.base.Signals.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.base.Signals.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.base.Signals} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.Signals.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getSignalList();
  if (f.length > 0) {
    writer.writeRepeatedMessage(
      1,
      f,
      proto.base.Signal.serializeBinaryToWriter
    );
  }
};


/**
 * repeated Signal signal = 1;
 * @return {!Array.<!proto.base.Signal>}
 */
proto.base.Signals.prototype.getSignalList = function() {
  return /** @type{!Array.<!proto.base.Signal>} */ (
    jspb.Message.getRepeatedWrapperField(this, proto.base.Signal, 1));
};


/** @param {!Array.<!proto.base.Signal>} value */
proto.base.Signals.prototype.setSignalList = function(value) {
  jspb.Message.setRepeatedWrapperField(this, 1, value);
};


/**
 * @param {!proto.base.Signal=} opt_value
 * @param {number=} opt_index
 * @return {!proto.base.Signal}
 */
proto.base.Signals.prototype.addSignal = function(opt_value, opt_index) {
  return jspb.Message.addToRepeatedWrapperField(this, 1, opt_value, proto.base.Signal, opt_index);
};


proto.base.Signals.prototype.clearSignalList = function() {
  this.setSignalList([]);
};



/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.base.PublisherConfig = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, null);
};
goog.inherits(proto.base.PublisherConfig, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  proto.base.PublisherConfig.displayName = 'proto.base.PublisherConfig';
}


if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto suitable for use in Soy templates.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     com.google.apps.jspb.JsClassTemplate.JS_RESERVED_WORDS.
 * @param {boolean=} opt_includeInstance Whether to include the JSPB instance
 *     for transitional soy proto support: http://goto/soy-param-migration
 * @return {!Object}
 */
proto.base.PublisherConfig.prototype.toObject = function(opt_includeInstance) {
  return proto.base.PublisherConfig.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Whether to include the JSPB
 *     instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.base.PublisherConfig} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.PublisherConfig.toObject = function(includeInstance, msg) {
  var f, obj = {
    signals: (f = msg.getSignals()) && proto.base.Signals.toObject(includeInstance, f),
    clientid: (f = msg.getClientid()) && common_pb.ClientId.toObject(includeInstance, f),
    frequency: jspb.Message.getFieldWithDefault(msg, 3, 0)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.base.PublisherConfig}
 */
proto.base.PublisherConfig.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.base.PublisherConfig;
  return proto.base.PublisherConfig.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.base.PublisherConfig} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.base.PublisherConfig}
 */
proto.base.PublisherConfig.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new proto.base.Signals;
      reader.readMessage(value,proto.base.Signals.deserializeBinaryFromReader);
      msg.setSignals(value);
      break;
    case 2:
      var value = new common_pb.ClientId;
      reader.readMessage(value,common_pb.ClientId.deserializeBinaryFromReader);
      msg.setClientid(value);
      break;
    case 3:
      var value = /** @type {number} */ (reader.readInt32());
      msg.setFrequency(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.base.PublisherConfig.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.base.PublisherConfig.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.base.PublisherConfig} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.PublisherConfig.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getSignals();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      proto.base.Signals.serializeBinaryToWriter
    );
  }
  f = message.getClientid();
  if (f != null) {
    writer.writeMessage(
      2,
      f,
      common_pb.ClientId.serializeBinaryToWriter
    );
  }
  f = message.getFrequency();
  if (f !== 0) {
    writer.writeInt32(
      3,
      f
    );
  }
};


/**
 * optional Signals signals = 1;
 * @return {?proto.base.Signals}
 */
proto.base.PublisherConfig.prototype.getSignals = function() {
  return /** @type{?proto.base.Signals} */ (
    jspb.Message.getWrapperField(this, proto.base.Signals, 1));
};


/** @param {?proto.base.Signals|undefined} value */
proto.base.PublisherConfig.prototype.setSignals = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


proto.base.PublisherConfig.prototype.clearSignals = function() {
  this.setSignals(undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.PublisherConfig.prototype.hasSignals = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional ClientId clientId = 2;
 * @return {?proto.base.ClientId}
 */
proto.base.PublisherConfig.prototype.getClientid = function() {
  return /** @type{?proto.base.ClientId} */ (
    jspb.Message.getWrapperField(this, common_pb.ClientId, 2));
};


/** @param {?proto.base.ClientId|undefined} value */
proto.base.PublisherConfig.prototype.setClientid = function(value) {
  jspb.Message.setWrapperField(this, 2, value);
};


proto.base.PublisherConfig.prototype.clearClientid = function() {
  this.setClientid(undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.PublisherConfig.prototype.hasClientid = function() {
  return jspb.Message.getField(this, 2) != null;
};


/**
 * optional int32 frequency = 3;
 * @return {number}
 */
proto.base.PublisherConfig.prototype.getFrequency = function() {
  return /** @type {number} */ (jspb.Message.getFieldWithDefault(this, 3, 0));
};


/** @param {number} value */
proto.base.PublisherConfig.prototype.setFrequency = function(value) {
  jspb.Message.setField(this, 3, value);
};



/**
 * Generated by JsPbCodeGenerator.
 * @param {Array=} opt_data Optional initial data array, typically from a
 * server response, or constructed directly in Javascript. The array is used
 * in place and becomes part of the constructed object. It is not cloned.
 * If no data is provided, the constructed object will be empty, but still
 * valid.
 * @extends {jspb.Message}
 * @constructor
 */
proto.base.Signal = function(opt_data) {
  jspb.Message.initialize(this, opt_data, 0, -1, null, proto.base.Signal.oneofGroups_);
};
goog.inherits(proto.base.Signal, jspb.Message);
if (goog.DEBUG && !COMPILED) {
  proto.base.Signal.displayName = 'proto.base.Signal';
}
/**
 * Oneof group definitions for this message. Each group defines the field
 * numbers belonging to that group. When of these fields' value is set, all
 * other fields in the group are cleared. During deserialization, if multiple
 * fields are encountered for a group, only the last value seen will be kept.
 * @private {!Array<!Array<number>>}
 * @const
 */
proto.base.Signal.oneofGroups_ = [[2,3,4,6]];

/**
 * @enum {number}
 */
proto.base.Signal.PayloadCase = {
  PAYLOAD_NOT_SET: 0,
  INTEGER: 2,
  DOUBLE: 3,
  ARBITRATION: 4,
  EMPTY: 6
};

/**
 * @return {proto.base.Signal.PayloadCase}
 */
proto.base.Signal.prototype.getPayloadCase = function() {
  return /** @type {proto.base.Signal.PayloadCase} */(jspb.Message.computeOneofCase(this, proto.base.Signal.oneofGroups_[0]));
};



if (jspb.Message.GENERATE_TO_OBJECT) {
/**
 * Creates an object representation of this proto suitable for use in Soy templates.
 * Field names that are reserved in JavaScript and will be renamed to pb_name.
 * To access a reserved field use, foo.pb_<name>, eg, foo.pb_default.
 * For the list of reserved names please see:
 *     com.google.apps.jspb.JsClassTemplate.JS_RESERVED_WORDS.
 * @param {boolean=} opt_includeInstance Whether to include the JSPB instance
 *     for transitional soy proto support: http://goto/soy-param-migration
 * @return {!Object}
 */
proto.base.Signal.prototype.toObject = function(opt_includeInstance) {
  return proto.base.Signal.toObject(opt_includeInstance, this);
};


/**
 * Static version of the {@see toObject} method.
 * @param {boolean|undefined} includeInstance Whether to include the JSPB
 *     instance for transitional soy proto support:
 *     http://goto/soy-param-migration
 * @param {!proto.base.Signal} msg The msg instance to transform.
 * @return {!Object}
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.Signal.toObject = function(includeInstance, msg) {
  var f, obj = {
    id: (f = msg.getId()) && common_pb.SignalId.toObject(includeInstance, f),
    integer: jspb.Message.getFieldWithDefault(msg, 2, 0),
    pb_double: +jspb.Message.getFieldWithDefault(msg, 3, 0.0),
    arbitration: jspb.Message.getFieldWithDefault(msg, 4, false),
    empty: jspb.Message.getFieldWithDefault(msg, 6, false),
    raw: msg.getRaw_asB64(),
    timestamp: jspb.Message.getFieldWithDefault(msg, 7, 0)
  };

  if (includeInstance) {
    obj.$jspbMessageInstance = msg;
  }
  return obj;
};
}


/**
 * Deserializes binary data (in protobuf wire format).
 * @param {jspb.ByteSource} bytes The bytes to deserialize.
 * @return {!proto.base.Signal}
 */
proto.base.Signal.deserializeBinary = function(bytes) {
  var reader = new jspb.BinaryReader(bytes);
  var msg = new proto.base.Signal;
  return proto.base.Signal.deserializeBinaryFromReader(msg, reader);
};


/**
 * Deserializes binary data (in protobuf wire format) from the
 * given reader into the given message object.
 * @param {!proto.base.Signal} msg The message object to deserialize into.
 * @param {!jspb.BinaryReader} reader The BinaryReader to use.
 * @return {!proto.base.Signal}
 */
proto.base.Signal.deserializeBinaryFromReader = function(msg, reader) {
  while (reader.nextField()) {
    if (reader.isEndGroup()) {
      break;
    }
    var field = reader.getFieldNumber();
    switch (field) {
    case 1:
      var value = new common_pb.SignalId;
      reader.readMessage(value,common_pb.SignalId.deserializeBinaryFromReader);
      msg.setId(value);
      break;
    case 2:
      var value = /** @type {number} */ (reader.readInt64());
      msg.setInteger(value);
      break;
    case 3:
      var value = /** @type {number} */ (reader.readDouble());
      msg.setDouble(value);
      break;
    case 4:
      var value = /** @type {boolean} */ (reader.readBool());
      msg.setArbitration(value);
      break;
    case 6:
      var value = /** @type {boolean} */ (reader.readBool());
      msg.setEmpty(value);
      break;
    case 5:
      var value = /** @type {!Uint8Array} */ (reader.readBytes());
      msg.setRaw(value);
      break;
    case 7:
      var value = /** @type {number} */ (reader.readInt64());
      msg.setTimestamp(value);
      break;
    default:
      reader.skipField();
      break;
    }
  }
  return msg;
};


/**
 * Serializes the message to binary data (in protobuf wire format).
 * @return {!Uint8Array}
 */
proto.base.Signal.prototype.serializeBinary = function() {
  var writer = new jspb.BinaryWriter();
  proto.base.Signal.serializeBinaryToWriter(this, writer);
  return writer.getResultBuffer();
};


/**
 * Serializes the given message to binary data (in protobuf wire
 * format), writing to the given BinaryWriter.
 * @param {!proto.base.Signal} message
 * @param {!jspb.BinaryWriter} writer
 * @suppress {unusedLocalVariables} f is only used for nested messages
 */
proto.base.Signal.serializeBinaryToWriter = function(message, writer) {
  var f = undefined;
  f = message.getId();
  if (f != null) {
    writer.writeMessage(
      1,
      f,
      common_pb.SignalId.serializeBinaryToWriter
    );
  }
  f = /** @type {number} */ (jspb.Message.getField(message, 2));
  if (f != null) {
    writer.writeInt64(
      2,
      f
    );
  }
  f = /** @type {number} */ (jspb.Message.getField(message, 3));
  if (f != null) {
    writer.writeDouble(
      3,
      f
    );
  }
  f = /** @type {boolean} */ (jspb.Message.getField(message, 4));
  if (f != null) {
    writer.writeBool(
      4,
      f
    );
  }
  f = /** @type {boolean} */ (jspb.Message.getField(message, 6));
  if (f != null) {
    writer.writeBool(
      6,
      f
    );
  }
  f = message.getRaw_asU8();
  if (f.length > 0) {
    writer.writeBytes(
      5,
      f
    );
  }
  f = message.getTimestamp();
  if (f !== 0) {
    writer.writeInt64(
      7,
      f
    );
  }
};


/**
 * optional SignalId id = 1;
 * @return {?proto.base.SignalId}
 */
proto.base.Signal.prototype.getId = function() {
  return /** @type{?proto.base.SignalId} */ (
    jspb.Message.getWrapperField(this, common_pb.SignalId, 1));
};


/** @param {?proto.base.SignalId|undefined} value */
proto.base.Signal.prototype.setId = function(value) {
  jspb.Message.setWrapperField(this, 1, value);
};


proto.base.Signal.prototype.clearId = function() {
  this.setId(undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.Signal.prototype.hasId = function() {
  return jspb.Message.getField(this, 1) != null;
};


/**
 * optional int64 integer = 2;
 * @return {number}
 */
proto.base.Signal.prototype.getInteger = function() {
  return /** @type {number} */ (jspb.Message.getFieldWithDefault(this, 2, 0));
};


/** @param {number} value */
proto.base.Signal.prototype.setInteger = function(value) {
  jspb.Message.setOneofField(this, 2, proto.base.Signal.oneofGroups_[0], value);
};


proto.base.Signal.prototype.clearInteger = function() {
  jspb.Message.setOneofField(this, 2, proto.base.Signal.oneofGroups_[0], undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.Signal.prototype.hasInteger = function() {
  return jspb.Message.getField(this, 2) != null;
};


/**
 * optional double double = 3;
 * @return {number}
 */
proto.base.Signal.prototype.getDouble = function() {
  return /** @type {number} */ (+jspb.Message.getFieldWithDefault(this, 3, 0.0));
};


/** @param {number} value */
proto.base.Signal.prototype.setDouble = function(value) {
  jspb.Message.setOneofField(this, 3, proto.base.Signal.oneofGroups_[0], value);
};


proto.base.Signal.prototype.clearDouble = function() {
  jspb.Message.setOneofField(this, 3, proto.base.Signal.oneofGroups_[0], undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.Signal.prototype.hasDouble = function() {
  return jspb.Message.getField(this, 3) != null;
};


/**
 * optional bool arbitration = 4;
 * Note that Boolean fields may be set to 0/1 when serialized from a Java server.
 * You should avoid comparisons like {@code val === true/false} in those cases.
 * @return {boolean}
 */
proto.base.Signal.prototype.getArbitration = function() {
  return /** @type {boolean} */ (jspb.Message.getFieldWithDefault(this, 4, false));
};


/** @param {boolean} value */
proto.base.Signal.prototype.setArbitration = function(value) {
  jspb.Message.setOneofField(this, 4, proto.base.Signal.oneofGroups_[0], value);
};


proto.base.Signal.prototype.clearArbitration = function() {
  jspb.Message.setOneofField(this, 4, proto.base.Signal.oneofGroups_[0], undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.Signal.prototype.hasArbitration = function() {
  return jspb.Message.getField(this, 4) != null;
};


/**
 * optional bool empty = 6;
 * Note that Boolean fields may be set to 0/1 when serialized from a Java server.
 * You should avoid comparisons like {@code val === true/false} in those cases.
 * @return {boolean}
 */
proto.base.Signal.prototype.getEmpty = function() {
  return /** @type {boolean} */ (jspb.Message.getFieldWithDefault(this, 6, false));
};


/** @param {boolean} value */
proto.base.Signal.prototype.setEmpty = function(value) {
  jspb.Message.setOneofField(this, 6, proto.base.Signal.oneofGroups_[0], value);
};


proto.base.Signal.prototype.clearEmpty = function() {
  jspb.Message.setOneofField(this, 6, proto.base.Signal.oneofGroups_[0], undefined);
};


/**
 * Returns whether this field is set.
 * @return {!boolean}
 */
proto.base.Signal.prototype.hasEmpty = function() {
  return jspb.Message.getField(this, 6) != null;
};


/**
 * optional bytes raw = 5;
 * @return {string}
 */
proto.base.Signal.prototype.getRaw = function() {
  return /** @type {string} */ (jspb.Message.getFieldWithDefault(this, 5, ""));
};


/**
 * optional bytes raw = 5;
 * This is a type-conversion wrapper around `getRaw()`
 * @return {string}
 */
proto.base.Signal.prototype.getRaw_asB64 = function() {
  return /** @type {string} */ (jspb.Message.bytesAsB64(
      this.getRaw()));
};


/**
 * optional bytes raw = 5;
 * Note that Uint8Array is not supported on all browsers.
 * @see http://caniuse.com/Uint8Array
 * This is a type-conversion wrapper around `getRaw()`
 * @return {!Uint8Array}
 */
proto.base.Signal.prototype.getRaw_asU8 = function() {
  return /** @type {!Uint8Array} */ (jspb.Message.bytesAsU8(
      this.getRaw()));
};


/** @param {!(string|Uint8Array)} value */
proto.base.Signal.prototype.setRaw = function(value) {
  jspb.Message.setField(this, 5, value);
};


/**
 * optional int64 timestamp = 7;
 * @return {number}
 */
proto.base.Signal.prototype.getTimestamp = function() {
  return /** @type {number} */ (jspb.Message.getFieldWithDefault(this, 7, 0));
};


/** @param {number} value */
proto.base.Signal.prototype.setTimestamp = function(value) {
  jspb.Message.setField(this, 7, value);
};


goog.object.extend(exports, proto.base);
