function cdxGenRandomKey(items) {
  var keys = (items || []).map(function (item) { return item.key; });
  var key;

  do {
    key = "xxxxxxxxxxxxxxxx".replace(/[x]/g, function (c) {
      const r = Math.floor(Math.random() * 16);
      return r.toString(16);
    });
  } while (keys.indexOf(key) != -1);

  return key;
}
