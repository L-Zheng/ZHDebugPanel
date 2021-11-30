
class ToastTool {
    static ToastFunc = null
    registerToast(func){
        ToastTool.ToastFunc = func
    }
    show(title, clickOp = null, type = 'default'){
        if (ToastTool.ToastFunc) {
            ToastTool.ToastFunc(title, clickOp, type)
        }
    }
}
export default new ToastTool();