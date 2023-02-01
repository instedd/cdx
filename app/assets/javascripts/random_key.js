function cdxGenRandomKey(items) {
  var keys;
  var key;

  if (items) {
    keys = items.map(function (item) { return item.key });
  } else {
    keys = [];
  }

  do {
    key = "xxxxxxxxxxxxxxxx".replace(/[x]/g, function (c) {
      const r = Math.floor(Math.random() * 16);
      return r.toString(16);
    });
  } while (keys.indexOf(key) != -1);

  return key;
}
