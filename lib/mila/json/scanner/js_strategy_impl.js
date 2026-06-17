function isEmpty(object) {
  return object === undefined || object === null || object.length === 0 || Object.keys(object).length === 0;
}

function compact(object) {
  if (Array.isArray(object)) {
    return object.filter(function (object) {
      return !isEmpty(object);
    })
  }
  return object
}

var Scanner = {
  extract: function (input) {
    var text = typeof input === 'string' ? input : String(input);
    var results = [];
    var pos = 0;

    while (pos < text.length) {
      while (pos < text.length && text[pos] !== '{' && text[pos] !== '[') {
        pos++;
      }

      if (pos >= text.length) break;

      var start = pos;
      try {
        var extracted = this.extractSingle(text, pos);
        if (extracted) {
          var jsonStr = extracted[0];
          var newPos = extracted[1];
          try {
            var parsed = JSON.parse(jsonStr);
            var compacted = compact(parsed);
            if (!isEmpty(compacted)) {
              results.push(compacted)
            }
          } catch (e) {
            // Invalid JSON, continue
          }
          pos = newPos;
        } else {
          pos = start + 1;
        }
      } catch (e) {
        pos = start + 1;
      }
    }

    return results;
  },

  extractSingle: function (text, start) {
    var stack = [];
    var inString = false;
    var escaped = false;
    var pos = start;

    var firstChar = text[start];
    if (firstChar !== '{' && firstChar !== '[') {
      return null;
    }

    stack.push(firstChar);

    while (pos < text.length && stack.length > 0) {
      pos++;
      var char = text[pos];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char === '\\') {
        escaped = true;
        continue;
      }

      if (char === '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char === '{' || char === '[') {
          stack.push(char);
        } else if (char === '}') {
          if (stack[stack.length - 1] === '{') {
            stack.pop();
          } else {
            return null;
          }
        } else if (char === ']') {
          if (stack[stack.length - 1] === '[') {
            stack.pop();
          } else {
            return null;
          }
        }
      }
    }

    if (stack.length === 0) {
      var jsonStr = text.slice(start, pos + 1);
      return [jsonStr, pos + 1];
    }

    return null;
  }
};

function extractJSONStrings(string) {
  return Scanner.extract(string).map(function (obj) {
    return JSON.stringify(obj);
  });
}

function extractJSONObjects(string) {
  return Scanner.extract(string)
}