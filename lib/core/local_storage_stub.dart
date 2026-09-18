final _data = <String, String>{};

String? readLocal(String key) => _data[key];

void writeLocal(String key, String value) => _data[key] = value;
