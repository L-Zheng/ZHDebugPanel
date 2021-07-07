
class JSTool {
    constructor() { }
    static Type = (() => {
        var type = {};
        var typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'Null', 'Symbol', 'Boolean', 'Arguments', 'Error'];
        for (var i = 0; i < typeArr.length; i++) {
            (function (name) {
                type['is' + name] = function (obj) {
                    return Object.prototype.toString.call(obj) == '[object ' + name + ']';
                }
            })(typeArr[i]);
        }
        return type;
    })();
    static timer = null;
    static canRun = true;
    debounce(fn, delay) {
        var func = () => {
            // 每当用户输入的时候把前一个 setTimeout clear 掉
            clearTimeout(JSTool.timer);
            // 然后又创建一个新的 setTimeout, 这样就能保证interval 间隔内如果时间持续触发，就不会执行 fn 函数
            JSTool.timer = setTimeout(() => {
                fn.apply(this, arguments);
            }, delay);
        };
        func()
        return func
    }
    throttle(fn, delay) {
        var func = () => {
            // 在函数开头判断标记是否为true，不为true则return
            if (!JSTool.canRun) return;
            // 立即设置为false
            JSTool.canRun = false;
            // 将外部传入的函数的执行放在setTimeout中
            setTimeout(() => {
                // 最后在setTimeout执行完毕后再把标记设置为true(关键)表示可以执行下一次循环了。
                // 当定时器没有执行的时候标记永远是false，在开头被return掉
                fn.apply(this, arguments);
                JSTool.canRun = true;
            }, delay);
        }
        func()
        return func
    }
    dataType(data) {
        return Object.prototype.toString.call(data)
    }
    isFunction(myFunc) {
        return JSTool.Type.isFunction(myFunc)
    }
    isArray(value) {
        return JSTool.Type.isArray(value)
    }
    isObject(value) {
        return JSTool.Type.isObject(value)
    }
    isJson(value) {
        return JSTool.Type.isObject(value)
    }
    isString(value) {
        return JSTool.Type.isString(value)
    }
    isNumber(value) {
        return JSTool.Type.isNumber(value)
    }
    isBoolean(value) {
        return JSTool.Type.isBoolean(value)
    }
    isUndefined(value) {
        return JSTool.Type.isUndefined(value)
    }
    isSymbol(value) {
        return JSTool.Type.isSymbol(value)
    }
    isNull(value) {
        return JSTool.Type.isNull(value)
    }
    isArguments(value) {
        return JSTool.Type.isArguments(value)
    }
    isError(value) {
        return JSTool.Type.isError(value)
    }

    fetchData(json, key, type) {
        const emptyData = function (type) {
            if (type == 'Object') return {}
            if (type == 'Array') return []
            if (type == 'String') return ''
            if (type == 'Number') return 0
            if (type == 'Boolean') return false
            return ''
        }
        if (!json || !JSTool.Type.isObject(json) || !JSTool.Type.isString(key)) {
            return emptyData(type)
        }
        if (!key || key.length == 0) {
            return emptyData(type)
        }
        let res = null
        for (const k in json) {
            if (json.hasOwnProperty(k)) {
                if (k.toLowerCase() == key.toLowerCase()) {
                    res = json[k];
                    break
                }
            }
        }
        if (JSTool.Type.isNull(res)) return emptyData(type)

        if (type == 'Object' && JSTool.Type.isObject(res)) return res;
        if (type == 'Array' && JSTool.Type.isArray(res)) return res;
        if (type == 'String') {
            if (JSTool.Type.isString(res)) return res;
            if (JSTool.Type.isNumber(res)) return res.toString();
        }
        if (type == 'Number') {
            if (JSTool.Type.isNumber(res)) return res;
            if (JSTool.Type.isString(res)) return parseFloat(res);
        }
        if (type == 'Boolean') {
            if (JSTool.Type.isBoolean(res)) {
                return res;
            }
            if (JSTool.Type.isNumber(res)) {
                return res == 0 ? false : true;
            }
            if (JSTool.Type.isString(res)) {
                return parseFloat(res) == 0 ? false : true;
            }
        }
        return emptyData(type)
    }
    //json取值 可防止js报错 or  数据异常
    fetchArray(json, key) {
        return this.fetchData(json, key, 'Array')
    }
    fetchJson(json, key) {
        return this.fetchData(json, key, 'Object')
    }
    fetchString(json, key) {
        return this.fetchData(json, key, 'String')
    }
    fetchNumber(json, key) {
        return this.fetchData(json, key, 'Number')
    }
    fetchBoolean(json, key) {
        return this.fetchData(json, key, 'Boolean')
    }
    insertJsonValue(json, key, value) {
        if (!json || !JSTool.Type.isObject(json) || !JSTool.Type.isString(key)) {
            return json
        }
        if (!key || key.length == 0) {
            return json
        }
        let isHave = false
        let haveKey = ''
        for (const k in json) {
            if (json.hasOwnProperty(k)) {
                if (k.toLowerCase() == key.toLowerCase()) {
                    haveKey = k;
                    isHave = true
                    break
                }
            }
        }
        if (isHave) {
            json[haveKey] = value
            return json
        }
        json[key] = value
        return json
    }

}
export default new JSTool();


