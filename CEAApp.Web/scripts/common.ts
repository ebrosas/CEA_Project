
// #region Enums
enum DateFormat {
    ddMMyyyy,
    yyyyMMdd
}

enum UserActionType {
    NoAction,
    CancelRequest,
    ApproveRequest,
    RejectRequest,
    ValidateRequest,
    ReassignRequest
}

enum CEAStatusCode {
    Draft = "Draft",
    Submitted = "Submitted",
    AwaitingChairmanApproval = "AwaitingChairmanApproval",
    DraftAndSubmitted = "DraftAndSubmitted",
    SubmittedForApproval = "SubmittedForApproval",
    UploadedToOneWorld = "UploadedToOneWorld",
    ChairmanApproved = "ChairmanApproved",
    Closed = "Closed",
    Approved = "Approved",
    Rejected = "Rejected",
    Cancelled = "Cancelled"
}
// #endregion

// #region Classes
class UserFormAccess {
    empNo: number;
    empName: string;
    costCenter: string;
    formCode: string;
    formName: string;
    formPublic: string;
    userFrmCRUDP: string;

    constructor() {
        this.empNo = 0;
        this.empName = "";
        this.costCenter = "";
        this.formCode = "";
        this.formName = "";
        this.formPublic = "";
        this.userFrmCRUDP = "";
    }
}

class UserAccessSearchFilter {
    mode: number;
    userFrmFormAppID: number;
    userFrmFormCode: string;
    userFrmCostCenter: string;
    userFrmEmpNo: number;

    constructor() {
        this.mode = 0;
        this.userFrmFormAppID = 0;
        this.userFrmFormCode = "";
        this.userFrmCostCenter = "";
        this.userFrmEmpNo = 0;
    }
}

class UserAccessParam {
    formCode: string;
    costCenter: string;
    empNo: number;

    constructor() {
        this.formCode = "";
        this.costCenter = "";
        this.empNo = 0;
    }
}

class CurrentLoggedUser {
    empNo: number;
    empName: string;
    userName: string;
    costCenter: string;
    costCenterName: string;
    email: string;

    constructor() {
        this.empNo = 0;
        this.empName = "";
        this.userName = "";
        this.costCenter = "";
        this.costCenterName = "";
        this.email = "";
    }
}

interface FormDataDictionary {
    key: string;
    value: string;
    type: string;
}

// #endregion

// #region Global Variables
var gContainer;
const gUserAccess = new UserFormAccess();
const gCurrentUser = new CurrentLoggedUser();

var toastTypes = {
    info: 0,
    success: 1,
    warning: 2,
    error: 3
}

const FormAccessIndex = {
    Create: 0,
    Retrieve: 1,
    Update: 2,
    Delete: 3,
    Print: 4
};

const PageNameList = {
    ProjectInquiry: "Project Inquiry",
    RequisitionInquiry: "Requisition Inquiry",
    ProjectDetail: "Project Details",
    DetailedExpensesReport: "DetailedExpenses Report",
    ExpensesReport: "Expenses Report",
    RequisitionReport: "Requisition Report",
    RequestAdmin: "Request Administration",
    EquipmentAssignment: "Equipment Assignment Number",
    ProjectUpload :"Project Upload",    
    CEAEntry: "CEA Requisition"
}

const PageControllerMapping = {
    ProjectInquiry: "Index",
    RequisitionInquiry: "RequisitionInquiry",
    CEARequisition: "CEARequisition",
    ProjectDetail: "ProjectDetail",
    RequisitionAdmin: "RequisitionAdmin",
    ManageEquipmentNo: "ManageEquipmentNo",
}

const FormActionType = {
    ReadOnly: 0,
    EditMode: 1,
    CreateNew: 2,
    Approval: 3,
    FetchEmployee: 4,
    Draft: 5,
    ShowReport: 6,
    ForValidation: 7,
    UploadToJDE: 8
}

const ApprovalStatus = {
    Draft: "Draft",
    Submitted: "Submitted for Approval",
    Approved: "Approved",
    Completed: "Completed",
    SubmittedForApproval: "Awaiting Approval",
    Rejected: "Rejected",
    AwaitingApproval: "In Queue",
    Cancelled: "Cancelled",
    Closed: "Closed",
    Active: "Active",
    ChairmanApproved: "Chairman Approved",
    UploadedToOneWorld: "Uploaded to OneWorld",
    DraftAndSubmitted: "All Open Statuses",
    AwaitingChairmanApproval: "Awaiting Chairman Approval",
    //RequisitionAdministration: "All Open Statuses",
    Terminated: "Terminated",
    Reassigned: "Reassigned",
    OnLeave: "On Leave",
    RejectedTmp: "Rejected",
    Notified: "Notified",
    Blank: "-",
    Resigned: "Resigned",
    Reactivated: "Reactivated",
    WaitingForApproval: "Waiting For Approval"
}

const StatusHandlingCodes = {
    Approved: "Approved",
    Cancelled: "Cancelled",
    Closed: "Closed",
    Draft: "Draft",
    Open: "Open",
    Rejected: "Rejected",
    Validated: "Validated",
    AllOpen: "All Open Statuses"
}

const gCONST_ALL = "valAll";
const gCONST_EMPTY = "valEmpty";
const gCONST_SUCCESS = "SUCCESS";
const gCONST_FAILED = "FAILED";

const CONST_RETRIEVE_DENIED = "Sorry, you don\'t have access to retrieve data. Please contact ICT or create a Helpdesk request!";
const CONST_CREATE_DENIED = "Sorry, you don\'t have access to create new record. Please contact ICT or create a Helpdesk request!";
const CONST_UPDATE_DENIED = "Sorry, you don\'t have access to update record. Please contact ICT or create a Helpdesk request!";
const CONST_DELETE_DENIED = "Sorry, you don\'t have access to delete record. Please contact ICT or create a Helpdesk request!";
const CONST_PRINT_DENIED = "Sorry, you don\'t have access to print a report. Please contact ICT or create a Helpdesk request!";
const CONST_RECALL_DENIED = "Sorry, you don\'t have access to recall this requisition. Only the creator, cost center manager, and system administrator can recall a request.";
// #endregion

//#region Show Error Methods
function HideErrorMessage() {
    $(".errorMsg").html("");
    $(".errorMsgBox").attr("hidden", "true");
}

function ShowErrorMessage(message: any) {
    $(".errorMsg").html(message);
    $(".errorMsgBox").removeAttr("hidden");
}

function ShowSuccessMessage(message) {
    $(".successMsg").html(message);
    $(".successMsgBox").removeAttr("hidden");
}

function ShowToastMessage(type, msgText, msgTitle) {
    switch (type) {
        case toastTypes.info:
            toastr.info(msgText, msgTitle,
                {
                    "closeButton": true,
                    "progressBar": true,
                    "newestOnTop": true,
                    "preventDuplicates": true
                });
            break;

        case toastTypes.success:
            toastr.success(msgText, msgTitle,
                {
                    "closeButton": true,
                    "progressBar": true,
                    "newestOnTop": true,
                    "preventDuplicates": true
                });
            break;

        case toastTypes.warning:
            toastr.warning(msgText, msgTitle,
                {
                    "closeButton": true,
                    "progressBar": true,
                    "newestOnTop": true,
                    "preventDuplicates": true
                });
            break;

        case toastTypes.error:
            toastr.error(msgText, msgTitle,
                {
                    "closeButton": true,
                    "progressBar": true,
                    "newestOnTop": true,
                    "preventDuplicates": true
                });
            break;
    }
}

function HideToastMessage() {
    toastr.clear();
}

function DisplayFormError(obj, errText, focusObj) {
    var alert = $(obj).find(".alert");

    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);

    if (obj != undefined)
        $(obj).removeAttr("hidden");

    $(alert).show();

    if (focusObj != undefined)
        $(focusObj).focus();
}
// #endregion

//#region Loading Panel Methods
function ShowLoadingPanel(container, num, text) {
    ShowWaitMe(container, num, text);
}

function HideLoadingPanel(container) {
    if (container != null && container != undefined)
        HideWaitMe(container);
}


function ShowWaitMe(container, num, text) {
    var effect = '',
        maxSize = '',
        fontSize = '',
        color = '',             // Color for background animation and text (string).
        textPos = ''            // Options: 'vertical' | 'horizontal'

    switch (num) {
        case 1: // Entire form
            effect = 'win8',
                maxSize = '200';
            fontSize = '20px';
            color = '#1E4A6D';
            textPos = 'vertical';
            break;

        case 2: // Selected section
            effect = 'stretch';
            maxSize = '200';
            fontSize = '14px';
            color = '#3F92B7', //'#000',
                textPos = 'horizontal';
            break;
    }

    if (container != null || container != undefined) {
        container.waitMe({
            effect: effect,
            text: text,
            bg: 'rgba(255,255,255,0.8)',
            color: color,
            maxSize: maxSize,
            source: '',
            textPos: textPos,
            fontSize: fontSize,
            waitTime: -1,
            onClose: function () { }
        });
    }
}

function HideWaitMe(container) {
    if (container != null || container != undefined) {
        container.waitMe('hide');
    }
}
//#endregion

//#region Helper Methods
function IsValidDate(dateInput) {
    try {
        var date = moment(dateInput, ["DD-MM-YYYY", "MM-DD-YYYY", "YYYY-MM-DD"]);
        return date.isValid();
    }
    catch (err) {
        return false;
    }
}

function CheckIfNoValue(obj) {
    return obj == undefined || obj == null || obj == "";
}

function ConvertToISODate(inputString) {
    try {
        var date = moment(inputString, ["DD-MM-YYYY", "MM-DD-YYYY", "YYYY-MM-DD"]);
        return date.format("YYYY-MM-DD");
    }
    catch (err) {
        return null;
    }
}

function GetDateValue(dtPicker, format): string {
    var result = "";

    if (dtPicker == null || dtPicker == undefined || dtPicker.val().length == 0)
        return result;

    var d = new Date(dtPicker.val());
    if (Object.prototype.toString.call(d) === "[object Date]") {
        if (!isNaN(d.getTime())) {
            if (format == DateFormat.ddMMyyyy)
                result = d.getDate() + "/" + d.getMonth() + 1 + "/" + d.getFullYear();
            else
                result = d.getFullYear() + "-" + d.getMonth() + 1 + "-" + d.getDate();
        }
    }
    return result;
}

function GetFormattedDate(inputDate, format): string {
    var result = "";

    if (inputDate == null || inputDate == undefined)
        return result;

    var d = new Date(inputDate);
    if (Object.prototype.toString.call(d) === "[object Date]") {
        if (!isNaN(d.getTime())) {
            let day = d.getDate();
            let month = d.getMonth() + 1;
            let year = d.getFullYear();

            if (format == DateFormat.ddMMyyyy)
                result = day.toString().padStart(2, "0") + "/" + month.toString().padStart(2, "0") + "/" + year.toString().padStart(4, "0");
            else
                result = year.toString().padStart(4, "0") + "-" + month.toString().padStart(2, "0") + 1 + "-" + day.toString().padStart(2, "0");

            //if (format == DateFormat.ddMMyyyy)
            //    result = day.toString() + "/" + month.toString() + "/" + year.toString();
            //else
            //    result = year.toString() + "-" + month.toString() + 1 + "-" + day.toString();
        }
    }
    return result;
}

function GetIntValue(inputString) {
    try {
        let value = parseInt(inputString);
        return isNaN(value) ? 0 : value;
    } catch (e) {
        return 0;
    }
}

function GetFloatValue(inputString) {
    try {
        let value = parseFloat(inputString);
        return isNaN(value) ? 0 : value;
    } catch (e) {
        return 0;
    }
}

function GetStringValue(input) {
    if (input != undefined && input != null) {
        return input.toString();
    }
    else
        return "";
}

function GetBooleanValue(input) {
    try {
        let value = Boolean(input);
        return value;
    } catch (e) {
        return false;
    }
}

function GetISODate(dateInput) {
    if (dateInput.length > 0)
        return new Date(dateInput).toISOString()
    else
        return "";
}

function CreateGUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function OnlyNumberKey(evt) {
    // Only ASCII character in that range allowed
    var ASCIICode = (evt.which) ? evt.which : evt.keyCode
    if (ASCIICode > 31 && (ASCIICode < 48 || ASCIICode > 57))
        return false;
    return true;
}

function OnlyNumberWithDecimal(evt) {
    // Only ASCII character in that range allowed
    var charCode = (evt.which) ? evt.which : evt.keyCode    
    if (charCode != 46 && charCode > 31 && (charCode < 48 || charCode > 57))
        return false;
    return true;
}

function IsNumberKey(txt, evt) {
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode == 46) {
        //Check if the text already contains the . character
        if (txt.value.indexOf('.') === -1) {
            return true;
        } else {
            return false;
        }
    } else {
        if (charCode > 31 &&
            (charCode < 48 || charCode > 57))
            return false;
    }
    return true;
}

function GetQueryStringValue(key) {
    key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&"); // escape RegEx control chars
    var match = location.search.match(new RegExp("[?&]" + key + "=([^&]+)(&|$)"));
    return match && decodeURIComponent(match[1].replace(/\+/g, " "));
}

function SaveDataToSession(key, value) {
    sessionStorage.setItem(key, value);
}

function GetDataFromSession(key) {
    return sessionStorage.getItem(key);
}

function DeleteDataFromSession(key) {
    sessionStorage.removeItem(key);
}

function SaveFormData(exceptionList: string[]) {
    const formDataArray: FormDataDictionary[] = [];

    // Save the value of all input text elements
    $(":text").each(function () {
        let controlKey = $(this).attr("name") as string;
        let controlValue = $(this).val() as string;

        let formData: FormDataDictionary = { key: controlKey, value: controlValue, type: "text" };
        formDataArray.push(formData);
    })

    // Save the value of all input number elements
    $("input[type=number]").each(function () {
        let controlKey = $(this).attr("name") as string;
        let controlValue = $(this).val() as string;

        let formData: FormDataDictionary = { key: controlKey, value: controlValue, type: "number" };
        formDataArray.push(formData);
    })

    // Save the value of all hidden fields
    $("input[type=hidden]").each(function () {
        let controlKey = $(this).attr("name") as string;
        let controlValue = $(this).val() as string;

        if (!CheckIfNoValue(controlKey)) {
            let formData: FormDataDictionary = { key: controlKey, value: controlValue, type: "hidden" };
            if (exceptionList.length > 0) {
                // Check if control is not included in the exception list
                if (!exceptionList.includes(controlKey)) {
                    formDataArray.push(formData);
                }
            }
            else
                formDataArray.push(formData);
        }
    })

    // Save the value of all select elements
    $("select").each(function () {
        let controlKey = $(this).attr("name") as string;
        let controlValue = $(this).val() as string;

        let formData: FormDataDictionary = { key: controlKey, value: controlValue, type: "select" };
        formDataArray.push(formData);
    })

    // Save the value of all textarea elements
    $("textarea").each(function () {
        let controlKey = $(this).attr("name") as string;
        let controlValue = $(this).val() as string;

        let formData: FormDataDictionary = { key: controlKey, value: controlValue, type: "textarea" };
        formDataArray.push(formData);
    })

    return formDataArray;
}

function RestoreFormData(dataArray) {
    let result = false;

    if (Array.isArray(dataArray)) {
        dataArray.forEach(function (value, index) {
            let formData: FormDataDictionary = { key: value.key, value: value.value, type: value.type };

            switch (formData.type) {
                case "text":
                case "number":
                case "hidden":
                    $('input[name="' + formData.key + '"]').val(formData.value);
                    break;

                case "select":
                    $('select[name="' + formData.key + '"]').val(formData.value);
                    break;

                case "textarea":
                    $('textarea[name="' + formData.key + '"]').val(formData.value);
                    break;
            }
        });

        result = true;
    }

    return result;
}
//#endregion

// #region User Form Access Methods
function HasAccess(userAccess, formAccessIndex) {
    if (CheckFormAccess(userAccess, formAccessIndex))
        return true;
    else
        return false;
}

function CheckFormAccess(access, formAccess) {
    var hasAccess = false;

    try {
        var formAccessIndex = Number(formAccess);
        if (access.length > formAccessIndex && String(access).substr(formAccessIndex, 1) == "1") {
            hasAccess = true;
        }

        return hasAccess;
    } catch (e) {
        return false;
    }
}
// #endregion

// #region Security Controller Methods
function GetUserCredential(userName, formCode, pageName) {
    try {

        // Get the current logged-in user id
        const userInfo = new CurrentLoggedUser();        
        userInfo.userName = userName;

        $.ajax({
            url: "/UserFunctions/Security/GetUserCredential",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: userInfo,
            success:
                function (response, status) {
                    if (status == "success") {
                        var model = response.data;
                        if (!CheckIfNoValue(model)) {
                            gCurrentUser.empNo = model.empNo;
                            gCurrentUser.empName = model.empName;
                            gCurrentUser.userName = model.userID;
                            gCurrentUser.costCenter = model.costCenter;
                            gCurrentUser.costCenterName = model.costCenterName;
                            gCurrentUser.email = model.email;            

                            // Fetch the user form access 
                            GetUserFormAccess(formCode, gCurrentUser.costCenter, gCurrentUser.empNo, pageName);

                            // Save to session
                            SaveDataToSession("UserCredential", JSON.stringify(gCurrentUser));
                        }
                    }
                    else {
                        throw new Error("Unable to find user access information from the database!");
                    }
                },
            error:
                function (err) {
                    throw err;
                }
        });
    }
    catch (err) {
        throw err;
    }
}

function GetUserFormAccess(formCode, costCenter, empNo, pageName) {
    try {

        const param = new UserAccessParam();
        param.formCode = formCode;
        param.costCenter = costCenter;
        param.empNo = empNo;

        $.ajax({
            url: "/UserFunctions/Security/GetUserFormAccess",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: false,
            data: param,
            success:
                function (response, status) {
                    if (status == "success") {
                        var model = response.data;
                        if (!CheckIfNoValue(model)) {
                            gUserAccess.empNo = model.empNo;
                            gUserAccess.empName = model.empName;
                            gUserAccess.costCenter = model.costCenter;
                            gUserAccess.formCode = model.formCode;
                            gUserAccess.formName = model.formName;
                            gUserAccess.formPublic = model.formPublic;
                            gUserAccess.userFrmCRUDP = model.userFrmCRUDP;

                            if (!CheckFormAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Retrieve)) {
                                // Current user has no access to view the form, so redirect the user to the No Access Violation page
                                location.href = "/UserFunctions/Security/NoAccessPage?pageName=".concat(pageName);
                            }
                        }
                    }
                    else {
                        throw new Error("Unable to find user access information from the database!");
                    }
                },
            error:
                function (err) {
                    throw err;
                }
        });
    }
    catch (err) {
        throw err;
    }
}
// #endregion


