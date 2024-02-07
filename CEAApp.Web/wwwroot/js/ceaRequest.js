//#region Classes
class EmpSearchCriteria {
    constructor() {
        this.projectNo = "";
        this.requisitionNo = "";
        this.expenditureType = "";
        this.fiscalYear = 0;
        this.statusCode = "";
        this.costCenter = "";
        this.empNo = 0;
        this.approvalType = "";
        this.filterToUser = false;
        this.keyWords = "";
        this.startDate = "";
        this.endDate = "";
        this.otherEmpNo = 0;
    }
}
class CEADetail {
    constructor() {
        this.callerForm = "";
        this.actionType = 0;
        this.requisitionStatus = "";
        this.projectNo = "";
        this.requisitionNo = "";
        this.requisitionID = 0;
        this.originatorEmpNo = 0;
        this.originatorEmpName = "";
        this.createDate = "";
        this.createdByEmpNo = 0;
        this.createdByEmpName = "";
        this.requestDate = "";
        this.description = "";
        this.costCenter = "";
        this.itemType = "";
        this.requisitionDescription = "";
        this.expenditureTypeCode = "";
        this.fiscalYear = 0;
        this.estimatedLifeSpan = 0;
        this.reason = "";
        this.plantLocationID = "";
        this.accountNo = "";
        this.equipmentNo = "";
        this.equipmentDesc = "";
        this.equipmentParentNo = "";
        this.equipmentParentDesc = "";
        this.dateofComission = "";
    }
}
class ScheduleExpense {
    constructor() {
        this.projectNo = "";
        this.amount = 0;
        this.fiscalYear = 0;
        this.quarter = "";
        this.lineNo = 0;
    }
}
//#endregion
// #region Declare objects and variables
var TabType;
(function (TabType) {
    TabType[TabType["NotSet"] = 0] = "NotSet";
    TabType[TabType["RequestDetail"] = 1] = "RequestDetail";
    TabType[TabType["Financial"] = 2] = "Financial";
    TabType[TabType["FileAttachment"] = 3] = "FileAttachment";
})(TabType || (TabType = {}));
var ButtonAction;
(function (ButtonAction) {
    ButtonAction[ButtonAction["NotSet"] = 0] = "NotSet";
    ButtonAction[ButtonAction["Draft"] = 1] = "Draft";
    ButtonAction[ButtonAction["Submit"] = 2] = "Submit";
    ButtonAction[ButtonAction["Delete"] = 3] = "Delete";
    ButtonAction[ButtonAction["Reject"] = 4] = "Reject";
    ButtonAction[ButtonAction["Approve"] = 5] = "Approve";
    ButtonAction[ButtonAction["Print"] = 6] = "Print";
})(ButtonAction || (ButtonAction = {}));
var ModalFormTypes;
(function (ModalFormTypes) {
    ModalFormTypes["Delete"] = "delete";
    ModalFormTypes["Reject"] = "reject";
    ModalFormTypes["Cancel"] = "cancel";
    ModalFormTypes["InvalidEstimatedCost"] = "invalid_cost";
    ModalFormTypes["RecallRequest"] = "recall";
    ModalFormTypes["ReactivateRequest"] = "reactivate";
    ModalFormTypes["ReopenRequest"] = "reopen";
    ModalFormTypes["ReassignRequest"] = "reassign";
})(ModalFormTypes || (ModalFormTypes = {}));
var ModalResponseTypes;
(function (ModalResponseTypes) {
    ModalResponseTypes["ModalYes"] = "modalYes";
    ModalResponseTypes["ModalNo"] = "modalNo";
    ModalResponseTypes["ModalCancel"] = "modalCancel";
    ModalResponseTypes["ModalSave"] = "modalSave";
    ModalResponseTypes["ModalDelete"] = "modalDelete";
    ModalResponseTypes["ModalReassign"] = "modalReassign";
})(ModalResponseTypes || (ModalResponseTypes = {}));
var ActionLinkTypes;
(function (ActionLinkTypes) {
    ActionLinkTypes["ActionRecall"] = "recall";
    ActionLinkTypes["ActionReactivate"] = "reactivate";
    ActionLinkTypes["ActionReopen"] = "reopen";
})(ActionLinkTypes || (ActionLinkTypes = {}));
var ChangeStatusActionType;
(function (ChangeStatusActionType) {
    ChangeStatusActionType["ReactivateRequest"] = "ActivateRequisition";
    ChangeStatusActionType["RecallRequest"] = "RecallRequisition";
    ChangeStatusActionType["ReopenRequest"] = "OpenRequisition";
})(ChangeStatusActionType || (ChangeStatusActionType = {}));
const ActionType = {
    ReadOnly: "0",
    EditMode: "1",
    CreateNew: "2",
    Approval: "3"
};
var defaultTab;
var selecteExpenseItem;
var selectedAttachment;
var selectedTab;
var modalFormType;
var modalResponse;
let equipListCount = 0;
let isAdditionalAmt = false;
let isSystemAdmin = false;
const expenseArray = [];
const attachmentArray = [];
const CONST_BASE64_KEY = "base64,";
// #endregion
// #region Document Initialization
$(() => {
    // Set the current container
    gContainer = $('.formWrapper');
    HideLoadingPanel(gContainer);
    HideErrorMessage();
    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    // Initialize action type
    let actionType = GetStringValue($("#hidActionType").val());
    // Check if current user is System Administrator
    isSystemAdmin = checkIfCEAAdmin();
    // #region Initialize event handlers
    $("#btnFindEmp").on('click', handleActionButtonClick);
    $("#btnAddExpense").on('click', handleActionButtonClick);
    $("#btnUpdateExpense").on('click', handleActionButtonClick);
    $("#btnCancelUpdate").on('click', handleActionButtonClick);
    $("#btnAddAttachment").on('click', handleActionButtonClick);
    $("#btnUpdateAttachment").on('click', handleActionButtonClick);
    $("#btnCancelAttachment").on('click', handleActionButtonClick);
    $("#btnReset").on('click', handleActionButtonClick);
    $("#btnDraft").on('click', handleActionButtonClick);
    $("#btnSubmit").on('click', handleActionButtonClick);
    $("#btnDelete").on('click', handleActionButtonClick);
    $("#btnPrint").on('click', handleActionButtonClick);
    $("#btnHiddenSubmit").on('click', handleActionButtonClick);
    $("#btnApprove").on('click', handleActionButtonClick);
    $("#btnReject").on('click', handleActionButtonClick);
    $("#btnReassign").on('click', handleActionButtonClick);
    $('input[name="RequisitionDescription"]').blur(function () {
        // Hide validation error 
        if ($('#RequisitionDescError').attr("hidden") == undefined)
            $('#RequisitionDescError').attr("hidden", "hidden");
    });
    $('input[name="OriginatorEmpName"]').blur(function () {
        // Hide validation error 
        if ($('#ReassignError').attr("hidden") == undefined)
            $('#ReassignError').attr("hidden", "hidden");
    });
    $('input[name="ReassignEmpNo"]').blur(function () {
        // Hide validation error 
        if ($('#OriginatorError').attr("hidden") == undefined)
            $('#OriginatorError').attr("hidden", "hidden");
    });
    $('input[name="DateofComission"]').blur(function () {
        // Hide validation error 
        if ($('#DateofComissionError').attr("hidden") == undefined)
            $('#DateofComissionError').attr("hidden", "hidden");
    });
    $('input[name="RequestedAmt"]').blur(function () {
        // Hide validation error 
        if ($('#RequestedAmtError').attr("hidden") == undefined)
            $('#RequestedAmtError').attr("hidden", "hidden");
        let estimatedCost = GetFloatValue($(this).val());
        let balanceAmount = GetFloatValue($('input[name="ProjectBalanceAmt"]').val());
        if (estimatedCost > balanceAmount) {
            // Calculate the additional amount value
            let addAmountCost = estimatedCost - balanceAmount;
            $("input[name='AdditionalBudgetAmt']").val(addAmountCost.toString());
            $("input[name='AdditionalBudgetAmtSync']").val(addAmountCost.toString());
        }
    });
    $('textarea[name="Description"]').blur(function () {
        // Hide validation error 
        if ($('#DescriptionError').attr("hidden") == undefined)
            $('#DescriptionError').attr("hidden", "hidden");
    });
    $('textarea[name="Reason"]').blur(function () {
        // Hide validation error 
        if ($('#ReasonError').attr("hidden") == undefined)
            $('#ReasonError').attr("hidden", "hidden");
    });
    $('select[name="CategoryCode1"]').blur(function () {
        // Hide validation error 
        if ($('#ItemTypeError').attr("hidden") == undefined)
            $('#ItemTypeError').attr("hidden", "hidden");
    });
    // Action links
    $("a[name='ActivateRequest']").on('click', handleActionLink);
    $("a[name='ReopenRequest']").on('click', handleActionLink);
    $("a[name='RecallRequest']").on('click', handleActionLink);
    $("#actionDiv a").hover(function () {
        $(this).addClass("bg-info");
    }, function () {
        $(this).removeClass("bg-info");
    });
    // Adjust the table column size when showing the modal form
    $('#modEquipment').on('shown.bs.modal', function () {
        var table = $('#equipmentTable').DataTable();
        table.columns.adjust();
    });
    // Adjust the table column size when navigating tab panels
    $('a[data-bs-toggle="tab"]').on('shown.bs.tab', function (e) {
        // Clear attachment table
        var attachmentTable = $("#attachmentTable").dataTable().api();
        attachmentTable.clear().draw();
        // Clear expense table
        var expenseTable = $("#expenseTable").dataTable().api();
        expenseTable.clear().draw();
        // Reload grids
        populateAttachmentTable(attachmentArray);
        populateSchedExpenseTable(expenseArray);
    });
    $(window).resize(function () {
        $("table.dataTable").resize();
    });
    // Modal form events
    $("#modConfirmation .modal-footer > button").on("click", handleModalButtonClick);
    $("#modChangeStatus .modal-footer > button").on("click", handleModalButtonClick);
    $("#modReassignment .modal-footer > button").on("click", handleModalButtonClick);
    // #endregion
    // #region Handle tab navigation
    $('a[data-bs-toggle="tab"]').on('click', function (e) {
        var target = $(e.target);
        if ($(target).closest('li').attr('id') == 'lnkDetail') {
            // #region Details tab
            // Set "RequisitionDetails" as the active tab
            //$("#lnkDetail").addClass("active");
            //if ($("#lnkFinancial").hasClass("active"))
            //    $("#lnkFinancial").removeClass("active");
            //if ($("#lnkAttachment").hasClass("active"))
            //    $("#lnkAttachment").removeClass("active");
            setActiveTab(TabType.RequestDetail);
            selectedTab = TabType.RequestDetail;
            // #endregion
        }
        else if ($(target).closest('li').attr('id') == 'lnkFinancial') {
            // #region Schedule of Expense tab
            // Set "Financial Details" as the active tab
            //$("#lnkFinancial").addClass("active");
            //if ($("#lnkDetail").hasClass("active"))
            //    $("#lnkDetail").removeClass("active");
            //if ($("#lnkAttachment").hasClass("active"))
            //    $("#lnkAttachment").removeClass("active");
            setActiveTab(TabType.Financial);
            selectedTab = TabType.Financial;
            // #endregion
        }
        else if ($(target).closest('li').attr('id') == 'lnkAttachment') {
            // #region File Attachment tab
            // Set "Attachment" as the active tab
            //$("#lnkAttachment").addClass("active");
            //if ($("#lnkDetail").hasClass("active"))
            //    $("#lnkDetail").removeClass("active");
            //if ($("#lnkFinancial").hasClass("active"))
            //    $("#lnkFinancial").removeClass("active");
            setActiveTab(TabType.FileAttachment);
            selectedTab = TabType.FileAttachment;
            // #endregion
        }
    });
    // #endregion
    // #region Initialize controls
    // Show red border to all required input controls
    $(".mandatoryField").on({
        focus: function () {
            $(this).css("border", "2px solid red");
            $(this).css("border-radius", "5px");
        },
        blur: function () {
            $(this).css("border", $("input:optional").css("border"));
            $(this).css("border-radius", $("input:optional").css("border"));
        }
    });
    //$("input:required").on({
    //    focus: function () {
    //        $(this).css("border", "2px solid red");
    //        $(this).css("border-radius", "5px");
    //    },
    //    blur: function () {
    //        $(this).css("border", $("input:optional").css("border"));
    //        $(this).css("border-radius", $("input:optional").css("border"));
    //    }
    //});
    //$("select:required").on({
    //    focus: function () {
    //        $(this).css("border", "2px solid red");
    //        $(this).css("border-radius", "5px");
    //    },
    //    blur: function () {
    //        $(this).css("border", $("input:optional").css("border"));
    //        $(this).css("border-radius", $("input:optional").css("border"));
    //    }
    //});
    //$("textarea:required").on({
    //    focus: function () {
    //        $(this).css("border", "2px solid red");
    //        $(this).css("border-radius", "5px");
    //    },
    //    blur: function () {
    //        $(this).css("border", $("input:optional").css("border"));
    //        $(this).css("border-radius", $("input:optional").css("border"));
    //    }
    //});
    // Setup datepickers
    $('input[name="RequestDate"]').datepicker({
        dateFormat: "dd/mm/yy",
        altField: "#hidRequestDate",
        altFormat: "yy-mm-dd",
        duration: "slow",
        prevText: "Click for previous months",
        nextText: "Click for next months",
        showOtherMonths: true,
        selectOtherMonths: true,
        changeMonth: true,
        changeYear: true,
        numberOfMonths: [1, 1],
        showWeek: false,
        showAnim: "slideDown"
    });
    $('input[name="DateofComission"]').datepicker({
        dateFormat: "dd/mm/yy",
        altField: "#hidDateofComission",
        altFormat: "yy-mm-dd",
        duration: "slow",
        prevText: "Click for previous months",
        nextText: "Click for next months",
        showOtherMonths: true,
        selectOtherMonths: true,
        changeMonth: true,
        changeYear: true,
        numberOfMonths: [1, 1],
        showWeek: false,
        showAnim: "slideDown"
    });
    // Fields that allow numbers only
    $('input[name="RequestedAmt"]').keypress(function () {
        return IsNumberKey(this, event);
    });
    $('input[name="ExpenseAmount"]').keypress(function () {
        return IsNumberKey(this, event);
    });
    // Show yellow background to all required fields
    //$('input,textarea,select').filter('[required]:visible').css("background-color", "yellow");
    //$('input[name="RequestedAmt"]').css("background-color", "yellow");
    // #region Set background color of the Status field
    let statusHandlingCode = $("input[name='StatusHandlingCode']").val();
    let ceaStatusCode = $("input[name='CEAStatusCode']").val();
    if (ceaStatusCode == "Submitted" || ceaStatusCode == "AwaitingChairmanApproval")
        $("#lblStatus").removeClass("bg-info").addClass("bg-primary");
    else if (ceaStatusCode == "Approved" || ceaStatusCode == "UploadedToOneWorld")
        $("#lblStatus").removeClass("bg-info").addClass("bg-success");
    else if (ceaStatusCode == "Cancelled")
        $("#lblStatus").removeClass("bg-info").addClass("bg-warning");
    else if (ceaStatusCode == "Rejected")
        $("#lblStatus").removeClass("bg-info").addClass("bg-danger");
    else if (ceaStatusCode == "Closed")
        $("#lblStatus").removeClass("bg-info").addClass("bg-secondary");
    // #endregion
    // Reset datatables
    populateSchedExpenseTable(null);
    populateAttachmentTable(null);
    // #endregion
    // #region Initialize buttons
    $("#actionDiv a").prop("hidden", true);
    switch (statusHandlingCode) {
        case StatusHandlingCodes.Draft:
            // Show "Save as Draft", "Submit", "Delete", and "Go Back"  buttons
            $("#btnDraft").prop("hidden", false);
            $("#btnSubmit").prop("hidden", false);
            $("#btnDelete").prop("hidden", false);
            $("#btnBack").prop("hidden", false);
            // Change action type to "Draft"
            actionType = FormActionType.Draft;
            break;
        case StatusHandlingCodes.Open:
            // Show "Print Requisition", "View Approvers", "View Expenses", "Recall this Requisition", Go Back  buttons
            $("#btnPrint").prop("hidden", false);
            $("#btnBack").prop("hidden", false);
            $("#btnView").prop("hidden", false);
            $("#actionDiv a[name='ViewExpenses'").prop("hidden", false);
            $("#actionDiv a[name='ViewApprovers'").prop("hidden", false);
            $("#actionDiv a[name='RecallRequest'").prop("hidden", false);
            // Set the backcolor of the currently assigned person label
            $("#lblAssignee").removeClass("bg-secondary");
            $("#lblAssignee").addClass("bg-primary");
            break;
        case StatusHandlingCodes.Approved:
        case StatusHandlingCodes.Rejected:
            // Show "Print Requisition", "View Approvers", "View Expenses", "Activate this Requisition", Go Back  buttons
            $("#btnPrint").prop("hidden", false);
            $("#btnBack").prop("hidden", false);
            $("#btnView").prop("hidden", false);
            $("#actionDiv a[name='ViewExpenses'").prop("hidden", false);
            $("#actionDiv a[name='ViewApprovers'").prop("hidden", false);
            $("#actionDiv a[name='ActivateRequest'").prop("hidden", false);
            break;
        case StatusHandlingCodes.Closed:
            // Show "Print Requisition", "View Approvers", "View Expenses", "Reopen this Requisition", Go Back  buttons
            $("#btnPrint").prop("hidden", false);
            $("#btnBack").prop("hidden", false);
            $("#btnView").prop("hidden", false);
            $("#actionDiv a[name='ViewExpenses'").prop("hidden", false);
            $("#actionDiv a[name='ViewApprovers'").prop("hidden", false);
            $("#actionDiv a[name='ReopenRequest'").prop("hidden", false);
            break;
        default:
            $("#btnReset").prop("hidden", false);
            break;
    }
    if (actionType == FormActionType.Draft) {
        // #region  Draft request
        // Enable input controls for data entry
        $('input[class~="editable"]').removeAttr("disabled");
        $('select[class~="editable"]').removeAttr("disabled");
        $('textarea[class~="editable"]').removeAttr("disabled");
        $('button[class~="editable"]').removeAttr("disabled");
        // Get attachments
        loadAttachment();
        // Get expenses
        loadExpenses();
        // #region Check if additional amount has been requested
        let additionalAmount = GetFloatValue($('input[name="AdditionalBudgetAmt"]').val());
        if (additionalAmount > 0) {
            // Enable "Reason for Addition Amount" field
            $("textarea[name='ReasonForAdditionalAmt']").prop("disabled", false);
            $("textarea[name='ReasonForAdditionalAmt']").prop("required", true);
            // Show request for additional amount badge
            $("#lblAdditionalAmount").prop("hidden", false);
            // Set the flag
            isAdditionalAmt = true;
        }
        // #endregion
        // #endregion
    }
    else if (actionType == FormActionType.ReadOnly) {
        // #region Submitted request
        // Hide the Edit and Delete buttons
        $("#expenseTable th[class~='buttonColumn']").addClass("hiddenColumn");
        //$("#attachmentTable th[class~='buttonColumn']").addClass("hiddenColumn");
        $("#attachmentTable th[class~='colDelete']").addClass("hiddenColumn");
        // Hide table's data entry controls
        $("#expenseEntry").attr("hidden", "hidden");
        $("#attachmentEntry").attr("hidden", "hidden");
        // Show the Reassign button if current user is a System Administrator
        if (isSystemAdmin) {
            if (ceaStatusCode == CEAStatusCode.Submitted || ceaStatusCode == CEAStatusCode.AwaitingChairmanApproval)
                $("#btnReassign").prop("hidden", false);
        }
        // Get attachments
        loadAttachment();
        // Get expenses
        loadExpenses();
        // #endregion
    }
    else if (actionType == FormActionType.Approval ||
        actionType == FormActionType.ForValidation) {
        // #region For Approval / Validation
        // Show "Save as Draft", "Submit", "Reset", and "Go Back"  buttons
        $('button[class~="approveBtn"').removeAttr("hidden");
        $('button[class~="viewBtn"').removeAttr("hidden");
        $('button[class~="generalBtn"').removeAttr("hidden");
        // Hide all other buttons
        $('button[class~="createBtn"').attr("hidden", "hidden");
        $('button[class~="updateBtn"').attr("hidden", "hidden");
        $("#btnReset").prop("hidden", true);
        $("#btnRecall").prop("hidden", true);
        // Show approver comments
        $("div.approverPanel").prop("hidden", false);
        // Hide data entry panel in the Schedule of Expense and Attachment section
        $("#expenseEntry").attr("hidden", "hidden");
        $("#attachmentEntry").attr("hidden", "hidden");
        // Hide the Edit and Delete buttons in the Schedule of Expenses and Attachment grid
        $("#expenseTable th[class~='buttonColumn']").addClass("hiddenColumn");
        $("#attachmentTable th[class~='colDelete']").addClass("hiddenColumn");
        // Resize the form to accomodate the display of the approver comments
        $("div .tab-content").css("height", "68vh");
        // Rmove yellow background to all required fields
        //$('input,textarea,select').filter('[required]:visible').css("background-color", "white");
        // Get attachments
        loadAttachment();
        // Get expenses
        loadExpenses();
        // #endregion
    }
    else if (actionType == FormActionType.CreateNew || actionType == FormActionType.FetchEmployee) {
        // #region Create new request
        // Enable input controls for data entry
        $('input[class~="editable"]').removeAttr("disabled");
        $('select[class~="editable"]').removeAttr("disabled");
        $('textarea[class~="editable"]').removeAttr("disabled");
        $('button[class~="editable"]').removeAttr("disabled");
        // Show "Save as Draft", "Submit", "Reset", and "Go Back"  buttons
        $('button[class~="createBtn"').removeAttr("hidden");
        $('button[class~="generalBtn"').removeAttr("hidden");
        // Hide all other buttons
        $('button[class~="approveBtn"').attr("hidden", "hidden");
        $('button[class~="viewBtn"').attr("hidden", "hidden");
        $('div[class~="viewBtn"').attr("hidden", "hidden");
        $('button[class~="updateBtn"').attr("hidden", "hidden");
        // #endregion
    }
    if (!(actionType == FormActionType.CreateNew ||
        (actionType == FormActionType.ReadOnly && (ceaStatusCode == CEAStatusCode.Rejected || ceaStatusCode == CEAStatusCode.Cancelled || ceaStatusCode == CEAStatusCode.Approved || ceaStatusCode == CEAStatusCode.Closed)))) {
        /*(actionType == FormActionType.ReadOnly && (statusHandlingCode == StatusHandlingCodes.Rejected || statusHandlingCode == StatusHandlingCodes.Cancelled || statusHandlingCode == StatusHandlingCodes.Approved || statusHandlingCode == StatusHandlingCodes.Closed)))) {*/
        // Hide the "Currently Assigned To" and "Approval Role" fields
        $("div.viewAssigned").prop("hidden", false);
    }
    // #endregion
    //#region Set the controller action method of the Back button
    let callerFormVal = $("#hidCallerForm").val();
    let url = $('a[class~="backButton"').attr("href");
    let baseUrl = "/UserFunctions/Project";
    // Append any query string values
    if (!CheckIfNoValue($("#hidQueryString").val())) {
        baseUrl = baseUrl.concat($("#hidQueryString").val());
    }
    if (CheckIfNoValue(callerFormVal)) {
        $('a[class~="backButton"').attr("href", baseUrl.concat("/").concat(PageControllerMapping.RequisitionInquiry.toString()));
    }
    else if (callerFormVal == PageControllerMapping.RequisitionAdmin.toString()) {
        baseUrl = "/AdminFunctions/Admin";
        $('a[class~="backButton"').attr("href", baseUrl.concat("/").concat(callerFormVal));
    }
    else {
        if (callerFormVal != PageControllerMapping.ProjectInquiry.toString()) {
            $('a[class~="backButton"').attr("href", baseUrl.concat("/").concat(callerFormVal));
        }
    }
    // #endregion
    // #region Initialize form security
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());
    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential);
        // Reinstantiate global variable 
        gCurrentUser.empNo = model.empNo;
        gCurrentUser.empName = model.empName;
        gCurrentUser.email = model.email;
        gCurrentUser.userName = model.userName;
        gCurrentUser.costCenter = model.costCenter;
        gCurrentUser.costCenterName = model.costCenterName;
        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.CEAEntry);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.ProjectInquiry);
    }
    // #endregion
    // #region Initialize button visibility based on user's access permission
    // Check if user has insert permission
    if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create)) {
        $('button[class~="createBtn"').removeAttr("disabled");
    }
    else {
        $('button[class~="createBtn"').attr("disabled", "disabled");
    }
    // Check if user has delete permission
    if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Delete)) {
        $('button[class~="updateBtn"').removeAttr("disabled");
    }
    else {
        $('button[class~="updateBtn"').attr("disabled", "disabled");
    }
    // #endregion
    // Initialize form data
    getOriginatorList();
    getEquipmentList();
    // #region Restore form data from the session
    let formData = GetDataFromSession("CEAFormData");
    if (!CheckIfNoValue(formData)) {
        const dataArray = JSON.parse(formData);
        if (RestoreFormData(dataArray)) {
            // Delete the session
            DeleteDataFromSession("CEAFormData");
        }
    }
    // #endregion
    // #region Restore file attachment from the session
    let attachmentSessionData = GetDataFromSession("AttachmentArray");
    if (!CheckIfNoValue(attachmentSessionData)) {
        const attachmentList = JSON.parse(attachmentSessionData);
        // Clear the array
        attachmentArray.length = 0;
        if (Array.isArray(attachmentList)) {
            attachmentList.forEach(function (value, index) {
                let attachmentItem = {
                    requisitionAttachmentID: value.requisitionAttachmentID,
                    requisitionID: value.requisitionID,
                    attachmentFileName: value.attachmentFileName,
                    attachmentDisplayName: value.attachmentDisplayName,
                    attachmentSize: value.attachmentSize,
                    createdByEmpNo: value.createdByEmpNo,
                    createdBy: value.createdBy,
                    createdDate: new Date(value.createdDate),
                    fileName: value.attachmentFileName.replace(/\s+/g, ''),
                    sequenceNo: attachmentArray.length + 1,
                    base64File: value.base64File,
                    base64FileExt: value.base64FileExt
                };
                // Add expense item to collection
                attachmentArray.push(attachmentItem);
            });
            var table = $('#attachmentTable').DataTable();
            table.columns.adjust();
            // Bind data to table
            populateAttachmentTable(attachmentArray);
        }
        // Delete the session
        DeleteDataFromSession("AttachmentArray");
    }
    // #endregion
    // #region Restore file Schedule of Expenses from the session
    let expenseSessionData = GetDataFromSession("ExpenseArray");
    if (!CheckIfNoValue(expenseSessionData)) {
        const expenseList = JSON.parse(expenseSessionData);
        // Clear the array
        expenseArray.length = 0;
        if (Array.isArray(expenseList)) {
            expenseList.forEach(function (value, index) {
                let expenseItem = {
                    fiscalYear: value.fiscalYear,
                    quarter: value.quarter,
                    amount: value.amount,
                    projectNo: $("input[name='ProjectNo']").val(),
                    lineNo: expenseList.length + 1
                };
                // Add expense item to collection
                expenseArray.push(expenseItem);
            });
            var table = $('#expenseTable').DataTable();
            table.columns.adjust();
            // Bind data to table
            populateSchedExpenseTable(expenseArray);
        }
        // Delete the session
        DeleteDataFromSession("ExpenseArray");
    }
    // #endregion
    //#region Get the selected employee
    let searchedEmpNo = $("#hidSearchEmpNo").val();
    let searchEmpName = $("#hidSearchEmpName").val();
    if (!CheckIfNoValue(searchedEmpNo)) {
        $("#hidOriginator").val(searchedEmpNo);
        $("#hidOriginatorEmpName").val(searchEmpName);
        $("#txtOriginator").val(searchEmpName);
    }
    //#endregion
});
// #endregion
// #region Web Methods
function checkIfCEAAdmin() {
    let currentUserEmpNo = GetIntValue($("input[name='UserEmpNo']").val());
    let isAdmin = false;
    if (!CheckIfNoValue($("#hidCEAAdminJSON").val())) {
        var adminList = JSON.parse($("#hidCEAAdminJSON").val());
        if (Array.isArray(adminList)) {
            adminList.find(o => {
                if (currentUserEmpNo == o.empNo) {
                    isAdmin = true;
                    return true;
                }
            });
        }
    }
    return isAdmin;
}
function loadAttachment() {
    if (!CheckIfNoValue($("#hidAttachmentJSON").val())) {
        var attachmentList = JSON.parse($("#hidAttachmentJSON").val());
        if (Array.isArray(attachmentList)) {
            attachmentList.forEach(function (value, index) {
                let attachmentItem = {
                    requisitionAttachmentID: value.requisitionAttachmentID,
                    requisitionID: value.requisitionID,
                    attachmentFileName: value.attachmentFileName,
                    attachmentDisplayName: value.attachmentDisplayName,
                    attachmentSize: value.attachmentSize,
                    createdByEmpNo: value.createdByEmpNo,
                    createdBy: value.createdBy,
                    createdDate: new Date(value.createdDate),
                    fileName: value.attachmentFileName.replace(/\s+/g, ''),
                    sequenceNo: attachmentArray.length + 1,
                    base64File: value.base64File,
                    base64FileExt: value.base64FileExt
                };
                // Add expense item to collection
                attachmentArray.push(attachmentItem);
            });
            // Bind data to table
            populateAttachmentTable(attachmentArray);
        }
    }
}
function loadExpenses() {
    if (!CheckIfNoValue($("#hidExpenseJSON").val())) {
        var expenseList = JSON.parse($("#hidExpenseJSON").val());
        if (Array.isArray(expenseList)) {
            expenseList.forEach(function (value, index) {
                let expenseItem = {
                    fiscalYear: value.fiscalYear,
                    quarter: value.quarter,
                    amount: value.amount,
                    projectNo: $("input[name='ProjectNo']").val(),
                    lineNo: expenseList.length + 1
                };
                // Add expense item to collection
                expenseArray.push(expenseItem);
            });
            // Bind data to table
            populateSchedExpenseTable(expenseArray);
        }
    }
}
function openOriginatorLookup() {
    ShowLoadingPanel(gContainer, 1, 'Loading Employee Lookup page, please wait...');
    //#region Save form data to session
    let findCEADetail = GetDataFromSession("CEAFormData");
    if (!CheckIfNoValue(findCEADetail))
        DeleteDataFromSession("CEAFormData");
    const exceptionList = ["UserName", "FormCode", "CallerForm", "ActionType", "SearchEmpNo"];
    let formData = SaveFormData(exceptionList);
    if (!CheckIfNoValue(formData))
        SaveDataToSession("CEAFormData", JSON.stringify(formData));
    // #endregion
    // #region Save File Attachment data
    // Delete existing data
    let findAttachmentArray = GetDataFromSession("AttachmentArray");
    if (!CheckIfNoValue(findAttachmentArray))
        DeleteDataFromSession("AttachmentArray");
    // Save data to session
    SaveDataToSession("AttachmentArray", JSON.stringify(attachmentArray));
    // #endregion
    // #region Save Schedule of Expenses data
    // Delete existing data
    let findExpenseArray = GetDataFromSession("ExpenseArray");
    if (!CheckIfNoValue(findExpenseArray))
        DeleteDataFromSession("ExpenseArray");
    // Save data to session
    SaveDataToSession("ExpenseArray", JSON.stringify(expenseArray));
    // #endregion
    // Open the Project Details View
    let actionType = FormActionType.FetchEmployee.toString();
    let callerForm = GetStringValue($("#hidCallerForm").val());
    let projectNo = $('input[name="ProjectNo"]').val().toString();
    location.href = "/UserFunctions/Project/EmployeeLookupView?callerForm=".concat(PageControllerMapping.CEARequisition.toString())
        .concat("&prevCallerForm=").concat(callerForm)
        .concat("&userCostCenter=").concat(gCurrentUser.costCenter)
        .concat("&projectNo=").concat(projectNo)
        .concat("&actionType=").concat(actionType);
}
function showErrorCEAEntry(obj, errText, focusObj) {
    let alert = $(obj).find(".alert");
    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);
    if (obj != undefined)
        $(obj).removeAttr("hidden");
    $(alert).show();
    if (focusObj != undefined)
        $(focusObj).focus();
}
function resetButtonClicked() {
    try {
        // Display loading panel
        ShowLoadingPanel(gContainer, 1, 'Refreshing the form, please wait...');
        HideErrorMessage();
        // Hide all error alerts
        $('.errorPanel').attr("hidden", "hidden");
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
        // Disable editable controls
        //$('[class*="editable"]').attr("disabled", "disabled");
        // Reset dataTables
        populateEquipmentTable(null);
        populateSchedExpenseTable(null);
        // Move to the top of the page
        window.scrollTo(0, 0);
        $("#btnHiddenReset").click();
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while refreshing the form: " + "<b>" + error.message + "</b>");
    }
    finally {
        gContainer = $('.formWrapper');
        HideLoadingPanel(gContainer);
    }
}
function showValidationError(obj, errText, focusObj) {
    var alert = $(obj).find(".alert");
    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);
    if (obj != undefined)
        $(obj).removeAttr("hidden");
    $(alert).show();
    if (focusObj != undefined)
        $(focusObj).focus();
}
function handleActionButtonClick() {
    var btn = $(this);
    var hasError = false;
    // Hide all error messages
    HideErrorMessage();
    HideToastMessage();
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
    switch ($(btn)[0].id) {
        case "btnDraft":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create)) {
                // Set the flag values
                $("input[name='IsDraft']").val("true");
                $("input[name='ButtonActionType']").val(ButtonAction.Draft.toString());
                // Save changes
                insertUpdateDeleteRequisition(ButtonAction.Draft);
            }
            else
                ShowToastMessage(toastTypes.error, CONST_CREATE_DENIED, "Access Denied");
            break;
        case "btnSubmit":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create)) {
                // Set the flag values
                $("input[name='IsDraft']").val("false");
                $("input[name='ButtonActionType']").val(ButtonAction.Submit.toString());
                // Save changes
                insertUpdateDeleteRequisition(ButtonAction.Submit);
            }
            else
                ShowToastMessage(toastTypes.error, CONST_CREATE_DENIED, "Access Denied");
            break;
        case "btnDelete":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Delete)) {
                // Set the modal header title
                modalFormType = ModalFormTypes.Delete;
                setModalTitle();
                // Show the confirmation box
                $("#modConfirmation").modal("show");
            }
            else
                ShowToastMessage(toastTypes.error, CONST_DELETE_DENIED, "Access Denied");
            break;
        case "btnFindEmp":
            openOriginatorLookup();
            break;
        case "btnAddExpense":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create))
                addExpenseItem();
            else
                ShowToastMessage(toastTypes.error, CONST_CREATE_DENIED, "Access Denied");
            break;
        case "btnUpdateExpense":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update))
                saveExpenseItem();
            else
                ShowToastMessage(toastTypes.error, CONST_UPDATE_DENIED, "Access Denied");
            break;
        case "btnCancelUpdate":
            cancelExpenseItem();
            break;
        case "btnAddAttachment":
            // Display loading panel
            gContainer = $('#tabAttachment');
            ShowLoadingPanel(gContainer, 2, 'Loading file attachment, please wait...');
            $("#uploadFile").trigger("click");
            break;
        case "btnUpdateAttachment":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update))
                saveAttachment();
            else
                ShowToastMessage(toastTypes.error, CONST_UPDATE_DENIED, "Access Denied");
            break;
        case "btnCancelAttachment":
            cancelFileAttachment();
            break;
        case "btnReset":
            resetButtonClicked();
            break;
        case "btnHiddenSubmit":
            $("input[name='ExpenseJSON'").val(JSON.stringify(expenseArray));
            $("input[name='AttachmentJSON'").val(JSON.stringify(attachmentArray));
            // Prevent executing the action method if there are validation errors
            //$("#btnHiddenSubmit").attr("formaction", "javascript:void(0);");
            var attachmentTable = $("#attachmentTable").dataTable().api();
            attachmentTable.clear().draw();
            populateAttachmentTable(attachmentArray);
            break;
        case "btnPrint":
            // #region Print CEA report 
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Print)) {
                // Display loading panel
                //ShowLoadingPanel(gContainer, 1, 'Print the report, please wait...');
                let requisitionNo = GetIntValue($("input[name='RequisitionNo']").val());
                if (!CheckIfNoValue(requisitionNo)) {
                    window.open("/ReportFunctions/Report/RequisitionPrint?requisitionId="
                        .concat(requisitionNo.toString())
                        .concat("&callerForm=").concat(PageControllerMapping.CEARequisition.toString()));
                    //HideLoadingPanel(gContainer);
                }
                else {
                    //HideLoadingPanel(gContainer);
                    ShowToastMessage(toastTypes.error, "Unable to print the CEA report because the requisition no. is not defined!.", "Error");
                }
            }
            else {
                //HideLoadingPanel(gContainer);
                ShowToastMessage(toastTypes.error, CONST_PRINT_DENIED, "Access Denied");
            }
            break;
        // #endregion
        case "btnApprove":
            beginApprovalProcess(true);
            break;
        case "btnReject":
            beginApprovalProcess(false);
            break;
        case "btnReassign":
            // Set modal form type
            modalFormType = ModalFormTypes.ReassignRequest;
            setModalTitle();
            // Show the change status box
            $("textarea[name='ReassignReason']").val("");
            $("#modReassignment").modal("show");
            break;
    }
}
function editButtonClickCEA() {
    // Enable controls
    $('[class*="editable"]').removeAttr("disabled");
    // Toggle buttons
    $("#btnEdit").attr("disabled", "disabled"); // Edit button
    $("#btnEdit").removeClass("btn-danger").removeClass("text-white").removeClass("border-0").addClass("btn-outline-danger");
    $("#btnCreate").attr("disabled", "disabled"); // Create button
    $("#btnCreate").removeClass("btn-primary").removeClass("text-white").removeClass("border-0").addClass("btn-outline-primary");
    $('[class*="backButton"]').addClass("disabled"); // Back button  
    $("#btnSave").removeAttr("disabled"); // Save button
    $("#btnSave").removeClass("btn-outline-success").addClass("btn-success").addClass("text-white");
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
}
function saveButtonClickCEA() {
    let hasError = false;
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
    // #region Validate Inputs
    // Check Fiscal Year
    if (CheckIfNoValue($('select[name="FiscalYear"]').val())) {
        showValidationError($('#FiscalYearError'), "<b>" + $(".fieldLabel label[data-field='FiscalYear']").text() + "</b> cannot be empty.", $('select[name="FiscalYear"]'));
        hasError = true;
    }
    else {
        if ($('#FiscalYearError').attr("hidden") == undefined)
            $('#FiscalYearError').attr("hidden", "hidden");
    }
    // Check Cost Center
    if (CheckIfNoValue($('select[name="CostCenter"]').val())) {
        showValidationError($('#CostCenterError'), "<b>" + $(".fieldLabel label[data-field='CostCenter']").text() + "</b> cannot be empty.", $('select[name="CostCenter"]'));
        hasError = true;
    }
    else {
        if ($('#CostCenterError').attr("hidden") == undefined)
            $('#CostCenterError').attr("hidden", "hidden");
    }
    // Check Expenditure Type
    if (CheckIfNoValue($('select[name="ExpenditureType"]').val())) {
        showValidationError($('#ExpenditureTypeError'), "<b>" + $(".fieldLabel label[data-field='ExpenditureType']").text() + "</b> cannot be empty.", $('select[name="ExpenditureType"]'));
        hasError = true;
    }
    else {
        if ($('#ExpenditureTypeError').attr("hidden") == undefined)
            $('#ExpenditureTypeError').attr("hidden", "hidden");
    }
    // Check Expected Project Date
    if (CheckIfNoValue($('input[name="ExpectedProjectDate"]').val())) {
        showValidationError($('#ExpectedProjectDateError'), "<b>" + $(".fieldLabel label[data-field='ExpectedProjectDate']").text() + "</b> cannot be empty.", $('input[name="ExpectedProjectDate"]'));
        hasError = true;
    }
    else {
        if ($('#ExpectedProjectDateError').attr("hidden") == undefined)
            $('#ExpectedProjectDateError').attr("hidden", "hidden");
    }
    // Check Description
    if (CheckIfNoValue($('textarea[name="Description"]').val())) {
        showValidationError($('#DescriptionError'), "<b>" + $(".fieldLabel label[data-field='Description']").text() + "</b> cannot be empty.", $('textarea[name="Description"]'));
        hasError = true;
    }
    else {
        if ($('#DescriptionError').attr("hidden") == undefined)
            $('#DescriptionError').attr("hidden", "hidden");
    }
    // Check Detailed Description
    if (CheckIfNoValue($('textarea[name="DetailDescription"]').val())) {
        showValidationError($('#DetailDescriptionError'), "<b>" + $(".fieldLabel label[data-field='DetailDescription']").text() + "</b> cannot be empty.", $('textarea[name="DetailDescription"]'));
        hasError = true;
    }
    else {
        if ($('#DetailDescriptionError').attr("hidden") == undefined)
            $('#DetailDescriptionError').attr("hidden", "hidden");
    }
    // Check Project Amount
    if (GetIntValue($('input[name="ProjectAmount"]').val()) == 0) {
        showValidationError($('#ProjectAmountError'), "<b>" + $(".fieldLabel label[data-field='ProjectAmount']").text() + "</b> cannot be empty.", $('input[name="ProjectAmount"]'));
        hasError = true;
    }
    else {
        if ($('#ProjectAmountError').attr("hidden") == undefined)
            $('#ProjectAmountError').attr("hidden", "hidden");
    }
    // #endregion
    if (!hasError) {
        ShowLoadingPanel(gContainer, 1, 'Saving information, please wait...');
        $("#btnHiddenSubmit").click();
    }
}
function addExpenseItem() {
    let hasError = false;
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
    // Hide all validation errors
    $('.expenseError .errorPanel').attr("hidden", "hidden");
    // #region Validate Inputs
    // Check Fiscal Year
    if (CheckIfNoValue($('select[name="ExpenseYear"]').val())) {
        $("div.expenseError").removeAttr("hidden");
        DisplayFormError($('#ExpenseYearError'), "<b>" + $("label[data-field='ExpenseYear']").text() + "</b> cannot be empty.", $('select[name="ExpenseYear"]'));
        hasError = true;
    }
    else {
        if ($('#ExpenseYearError').attr("hidden") == undefined)
            $('#ExpenseYearError').attr("hidden", "hidden");
    }
    // Check Quarter
    if (CheckIfNoValue($('select[name="ExpenseQuarter"]').val())) {
        $("div.expenseError").removeAttr("hidden");
        DisplayFormError($('#ExpenseQuarterError'), "<b>" + $("label[data-field='ExpenseQuarter']").text() + "</b> cannot be empty.", $('select[name="ExpenseQuarter"]'));
        hasError = true;
    }
    else {
        if ($('#ExpenseQuarterError').attr("hidden") == undefined)
            $('#ExpenseQuarterError').attr("hidden", "hidden");
    }
    // Check Expenditure Type
    if (CheckIfNoValue($('input[name="ExpenseAmount"]').val())) {
        $("div.expenseError").removeAttr("hidden");
        DisplayFormError($('#ExpenseAmountError'), "<b>" + $("label[data-field='ExpenseAmount']").text() + "</b> cannot be empty.", $('input[name="ExpenseAmount"]'));
        hasError = true;
    }
    else {
        if ($('#ExpenseAmountError').attr("hidden") == undefined)
            $('#ExpenseAmountError').attr("hidden", "hidden");
    }
    if (!hasError) {
        //ShowLoadingPanel(gContainer, 1, 'Saving expense item, please wait...');
        let expenseItem = {
            fiscalYear: GetIntValue($("select[name='ExpenseYear']").val()),
            quarter: $("select[name='ExpenseQuarter']").val(),
            amount: GetFloatValue($("input[name='ExpenseAmount']").val()),
            projectNo: $("input[name='ProjectNo']").val(),
            lineNo: expenseArray.length + 1
        };
        // Add expense item to collection
        expenseArray.push(expenseItem);
        // Clear expense controls
        $('select[name="ExpenseYear"').val("");
        $('select[name="ExpenseQuarter"').val("");
        $('input[name="ExpenseAmount"').val("");
        // Bind data tot table
        populateSchedExpenseTable(expenseArray);
        //HideLoadingPanel(gContainer);
        //ShowToastMessage(toastTypes.success, "Expense item has been added successfully!", "Add Record Successful");
    }
}
function saveExpenseItem() {
    try {
        let hasError = false;
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
        // Hide all validation errors
        $('.expenseError .errorPanel').attr("hidden", "hidden");
        if (CheckIfNoValue(selecteExpenseItem)) {
            ShowToastMessage(toastTypes.error, "Could not find details of the selected expense item.", "Error");
            return;
        }
        // Display loading panel
        gContainer = $('#tabFinancial');
        ShowLoadingPanel(gContainer, 2, 'Saving expense item, please wait...');
        // #region Validate Inputs
        // Check Fiscal Year
        if (CheckIfNoValue($('select[name="ExpenseYear"').val())) {
            $("div.expenseError").removeAttr("hidden");
            DisplayFormError($('#ExpenseYearError'), "<b>" + $("label[data-field='ExpenseYear']").text() + "</b> cannot be empty.", $('select[name="ExpenseYear"'));
            hasError = true;
        }
        else {
            if ($('#ExpenseYearError').attr("hidden") == undefined)
                $('#ExpenseYearError').attr("hidden", "hidden");
        }
        // Check Quarter
        if (CheckIfNoValue($('select[name="ExpenseQuarter"').val())) {
            $("div.expenseError").removeAttr("hidden");
            DisplayFormError($('#ExpenseQuarterError'), "<b>" + $("label[data-field='ExpenseQuarter']").text() + "</b> cannot be empty.", $('select[name="ExpenseQuarter"'));
            hasError = true;
        }
        else {
            if ($('#ExpenseQuarterError').attr("hidden") == undefined)
                $('#ExpenseQuarterError').attr("hidden", "hidden");
        }
        // Check Expenditure Type
        if (CheckIfNoValue($('input[name="ExpenseAmount"').val())) {
            $("div.expenseError").removeAttr("hidden");
            DisplayFormError($('#ExpenseAmountError'), "<b>" + $("label[data-field='ExpenseAmount']").text() + "</b> cannot be empty.", $('input[name="ExpenseAmount"'));
            hasError = true;
        }
        else {
            if ($('#ExpenseAmountError').attr("hidden") == undefined)
                $('#ExpenseAmountError').attr("hidden", "hidden");
        }
        //#endregion
        if (!hasError) {
            selecteExpenseItem.fiscalYear = GetIntValue($("select[name='ExpenseYear']").val());
            selecteExpenseItem.quarter = $("select[name='ExpenseQuarter']").val();
            selecteExpenseItem.amount = GetFloatValue($("input[name='ExpenseAmount']").val());
            // Clear expense controls
            $('select[name="ExpenseYear"').val("");
            $('select[name="ExpenseQuarter"').val("");
            $('input[name="ExpenseAmount"').val("");
            // Setup button visibility            
            if ($("#btnAddExpense").hasClass("disabled"))
                $("#btnAddExpense").removeClass("disabled");
            $("#btnUpdateExpense").addClass("disabled");
            $("#btnCancelUpdate").addClass("disabled");
            // Enable expense table
            if ($("#expenseTablePanel").hasClass("opacity-25"))
                $("#expenseTablePanel").removeClass("opacity-25");
            $("#expenseTablePanel").find("button").removeAttr("disabled");
            // Bind data tot table
            populateSchedExpenseTable(expenseArray);
            // Clear selected expense item 
            selecteExpenseItem = null;
            // Show notification
            //ShowToastMessage(toastTypes.success, "Expense item has been updated successfully!", "Update Successful");
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while updating the expense item: " + "<b>" + error.message + "</b>");
    }
    finally {
        gContainer = $('.formWrapper');
        HideLoadingPanel(gContainer);
    }
}
function cancelExpenseItem() {
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
    // Clear expense controls
    $('select[name="ExpenseYear"').val("");
    $('select[name="ExpenseQuarter"').val("");
    $('input[name="ExpenseAmount"').val("");
    // Setup button visibility
    if ($("#btnAddExpense").hasClass("disabled"))
        $("#btnAddExpense").removeClass("disabled");
    $("#btnUpdateExpense").addClass("disabled");
    $("#btnCancelUpdate").addClass("disabled");
    // Enable expense table
    if ($("#expenseTablePanel").hasClass("opacity-25"))
        $("#expenseTablePanel").removeClass("opacity-25");
    $("#expenseTablePanel").find("button").removeAttr("disabled");
    // Bind data tot table
    populateSchedExpenseTable(expenseArray);
    // Clear selected expense item 
    selecteExpenseItem = null;
}
function deleteExpenseItem() {
    try {
        // Display loading panel
        gContainer = $('#expenseTablePanel');
        ShowLoadingPanel(gContainer, 2, 'Deleting expense item, please wait...');
        let lineNo = GetIntValue($(this).attr("data-lineno"));
        if (lineNo > 0) {
            // Find the expense item from the array
            let itemIndex = expenseArray.findIndex(function (arr) {
                return arr.lineNo = lineNo;
            });
            // Remove item from the array
            expenseArray.splice(itemIndex, 1);
            // Bind data to table
            populateSchedExpenseTable(expenseArray);
            // Show notification
            ShowToastMessage(toastTypes.success, "Expense item has been remove successfully!", "Delete Successful");
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while deleting the selected expense item: " + "<b>" + error.message + "</b>");
    }
    finally {
        gContainer = $('.formWrapper');
        HideLoadingPanel(gContainer);
    }
}
function editExpenseItem() {
    let projectNo = $(this).attr("data-projectno");
    let fiscalYear = GetIntValue($(this).attr("data-fiscalyear"));
    let quarter = $(this).attr("data-quarter");
    let amount = GetFloatValue($(this).attr("data-amount"));
    let lineNo = GetIntValue($(this).attr("data-lineno"));
    if (lineNo > 0) {
        // Find the expense item from the array
        selecteExpenseItem = expenseArray.find(function (arr) {
            return arr.lineNo = lineNo;
        });
        if (!CheckIfNoValue(fiscalYear))
            $("select[name='ExpenseYear']").val(fiscalYear);
        if (!CheckIfNoValue(quarter))
            $("select[name='ExpenseQuarter']").val(quarter);
        if (!CheckIfNoValue(amount))
            $("input[name='ExpenseAmount']").val(amount);
        // Setup button visibility       
        $("#btnAddExpense").addClass("disabled");
        $("#btnUpdateExpense").removeClass("disabled");
        $("#btnCancelUpdate").removeClass("disabled");
        // Disable the expense table
        $("#expenseTablePanel").addClass("opacity-25");
        $("#expenseTablePanel").find("button").attr("disabled", "disabled");
        // Set focus to fiscal year
        $("select[name='ExpenseYear']").focus();
    }
    else {
        ShowToastMessage(toastTypes.error, "Could not find details of the selected expense item.", "Error");
    }
}
function populateSchedExpenseTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#expenseTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "Schedule of Expense Report";
        $("#expenseTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
            //// Disable the "Create New" button if user doesn't have insert record access
            //if (!HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create))
            //    $('a[class~="createCEAButton"]').addClass("disabled");
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            orderMulti: false,
            destroy: true,
            scrollX: true,
            language: {
                emptyTable: "No expense records found."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[0, 'asc'], [1, 'asc']],
            drawCallback: function () {
                $('button[class~="deleteExpenseButton"]').on('click', deleteExpenseItem);
                $('button[class~="editExpenseButton"]').on('click', editExpenseItem);
            },
            dom: "<'row' <'col-sm-3'l> <'col-sm-6 text-center'> <'col-sm-3'f> >" +
                "<'row'<'col-sm-12 col-md-12'tr>>" +
                "<'row'<'col-xs-12 col-sm-5 col-md-5'i><'col-xs-12 col-sm-7 col-md-7'p>>",
            buttons: [
                {
                    text: '<i class="fas fa-file-excel fa-lg fa-fw"></i>',
                    extend: 'excel',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Export results to Excel',
                    title: reportTitle
                },
                {
                    text: '<i class="fas fa-file-csv fa-lg fa-fw"></i>',
                    extend: 'csv',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Export results to CSV',
                    title: reportTitle
                },
                {
                    text: '<i class="fas fa-print fa-lg fa-fw"></i>',
                    extend: 'print',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Print results'
                }
            ],
            columns: [
                {
                    data: "fiscalYear"
                },
                {
                    data: "quarter"
                },
                {
                    data: "amount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: null
                },
                {
                    data: null
                },
                {
                    data: "projectNo"
                }
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                {
                    targets: 3,
                    render: function (data, type, row) {
                        return '<button class="btn btn-sm btn-success text-white rounded-pill m-1 editExpenseButton" style="width: 100px;" ' +
                            'data-projectno=' + row.projectNo + ' data-fiscalyear=' + row.fiscalYear + ' data-quarter=' + row.quarter + ' data-amount=' + row.amount + ' data-lineno=' + row.lineNo + '> ' +
                            '<span> <i class="fas fa-edit fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "Edit" + '</button>' + '</label>';
                    }
                },
                {
                    targets: 4,
                    render: function (data, type, row) {
                        return '<button class="btn btn-sm btn-danger text-white rounded-pill m-1 deleteExpenseButton" style="width: 100px;" ' +
                            'data-projectno=' + row.projectNo + ' data-fiscalyear=' + row.fiscalYear + ' data-quarter=' + row.quarter + ' data-amount=' + row.amount + ' data-lineno=' + row.lineNo + '> ' +
                            '<span> <i class="fas fa-trash-alt fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "Delete" + '</button>' + '</label>';
                    }
                },
                {
                    targets: "hiddenColumn",
                    visible: false
                },
                {
                    targets: "doNotOrder",
                    orderable: false
                }
            ]
        });
    }
}
function populateAttachmentTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#attachmentTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "File Attachments Report";
        $("#attachmentTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            orderMulti: false,
            destroy: true,
            scrollX: true,
            //autoWidth: false,
            language: {
                emptyTable: "No file attachment found."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[8, 'asc']],
            drawCallback: function () {
                $('.lnkFileName').on('click', openFileAttachment);
                $('button[class~="deleteAttachmentButton"]').on('click', deleteAttachment);
                $('button[class~="downloadAttachButton"]').on('click', downloadAttachment);
                //$('button[class~="downloadAttachButton"]').on('click', downloadLocalFile);
            },
            dom: "<'row' <'col-sm-3'l> <'col-sm-6 text-center'> <'col-sm-3'f> >" +
                "<'row'<'col-sm-12 col-md-12'tr>>" +
                "<'row'<'col-xs-12 col-sm-5 col-md-5'i><'col-xs-12 col-sm-7 col-md-7'p>>",
            buttons: [
                {
                    text: '<i class="fas fa-file-excel fa-lg fa-fw"></i>',
                    extend: 'excel',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Export results to Excel',
                    title: reportTitle
                },
                {
                    text: '<i class="fas fa-file-csv fa-lg fa-fw"></i>',
                    extend: 'csv',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Export results to CSV',
                    title: reportTitle
                },
                {
                    text: '<i class="fas fa-print fa-lg fa-fw"></i>',
                    extend: 'print',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Print results'
                }
            ],
            columns: [
                {
                    data: "attachmentDisplayName",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "attachmentSize",
                    render: $.fn.dataTable.render.number(',', '', 0) // Format: DataTable.render.number(thousands, decimal, precision, prefix, postfix) 
                },
                {
                    data: "createdBy",
                    render: function (data) {
                        return '<label">' + data + '</label>';
                    }
                },
                {
                    data: "createdDate",
                    render: function (data) {
                        return '<label">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: null
                },
                {
                    data: null
                },
                {
                    data: "attachmentFileName"
                },
                {
                    data: "requisitionAttachmentID"
                },
                {
                    data: "sequenceNo"
                }
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                //{
                //    targets: 0,     // attachmentDisplayName
                //    render: function (data, type, row) {
                //        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + '<a href="javascript:void(0)" class="lnkFileName gridLink" style="font-size: 14px;" data-attachmentid=' + row.requisitionAttachmentID + ' data-filename=' + row.attachmentFileName + '> ' + data + '</a>' + '</label>';
                //    }
                //},
                {
                    targets: 4,
                    render: function (data, type, row) {
                        return '<button class="btn btn-sm btn-success text-white rounded-pill m-1 downloadAttachButton" ' +
                            'data-attachmentid=' + row.requisitionAttachmentID + ' data-filename=' + row.fileName + '> ' +
                            '<span> <i class="fas fa-download fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "Download" + '</button>';
                    }
                },
                {
                    targets: 5,
                    render: function (data, type, row) {
                        return '<button class="btn btn-sm btn-danger text-white rounded-pill m-1 deleteAttachmentButton" ' +
                            'data-attachmentid=' + row.requisitionAttachmentID + ' data-filename=' + row.fileName + '> ' +
                            '<span> <i class="fas fa-trash-alt fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "Delete" + '</button>';
                    }
                },
                {
                    targets: "hiddenColumn",
                    visible: false
                },
                {
                    targets: "doNotOrder",
                    orderable: false
                }
            ]
        });
    }
}
function openFileAttachment() {
    try {
        let attachmentid = 0;
        let fileName = "";
        if (!CheckIfNoValue($(this).attr("data-attachmentid")))
            attachmentid = GetIntValue($(this).attr("data-attachmentid"));
        if (!CheckIfNoValue($(this).attr("data-filename")))
            fileName = $(this).attr("fileName");
        ShowLoadingPanel(gContainer, 1, 'Loading attachment, please wait...');
        // Open the Requisition Status View
        //location.href = "/UserFunctions/Project/RequisitionStatusView?requisitionID=".concat(requisitionID).concat("&projectNo=").concat(projectNo).concat("&requisitionNo=").concat(requisitionNo).concat("&createdNo=").concat(createdNo).concat("&createdName=").concat(createdName).concat("&submittedDate=").concat(submittedDate);
    }
    catch (error) {
        ShowErrorMessage("The following error has occured when opening the file attachment: " + "<b>" + error.message + "</b>");
    }
    finally {
        gContainer = $('.formWrapper');
        HideLoadingPanel(gContainer);
    }
}
function cancelFileAttachment() {
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
    gContainer = $('#tabAttachment');
    ShowLoadingPanel(gContainer, 2, 'Refreshing the attachment form, please wait...');
    // Clear unput controls
    $("#attachmentEntry input").val("");
    // Setup button visibility
    if ($("#btnAddAttachment").hasClass("disabled"))
        $("#btnAddAttachment").removeClass("disabled");
    $("#btnUpdateAttachment").addClass("disabled");
    $("#btnCancelAttachment").addClass("disabled");
    // Enable expense table
    if ($("#attachmentTablePanel").hasClass("opacity-25"))
        $("#attachmentTablePanel").removeClass("opacity-25");
    $("#attachmentTablePanel").find("button").removeAttr("disabled");
    // Bind data tot table
    populateAttachmentTable(attachmentArray);
    // Clear selected expense item 
    selectedAttachment = null;
}
function getUploadedFile(element) {
    try {
        // Hide the panel
        HideLoadingPanel(gContainer);
        var file = element.files[0];
        let fileName = file.name;
        let fileNameOnly = fileName.substring(0, fileName.lastIndexOf('.'));
        // Display the file information
        $("#hidFileName").val(file.name);
        $("input[name='DisplayName']").val(fileNameOnly);
        $("input[name='FileType']").val(file.type);
        $("input[name='FileSize']").val(GetIntValue(file.size / 1024));
        // Setup buttons
        $("#btnAddAttachment").addClass("disabled");
        $("#btnUpdateAttachment").removeClass("disabled");
        $("#btnCancelAttachment").removeClass("disabled");
        var reader = new FileReader();
        reader.onloadend = function () {
            var base64String = reader.result;
            if (!CheckIfNoValue(base64String))
                $("#hidBase64File").val(base64String);
        };
        reader.readAsDataURL(file);
    }
    catch (err) {
        ShowErrorMessage("The following error has occured while executing getUploadedFile() method.\n\n" + err);
    }
    finally {
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
        // Set the global form container
        gContainer = $('.formWrapper');
    }
}
function saveAttachment() {
    try {
        let hasError = false;
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
        // Display loading panel
        gContainer = $('#tabAttachment');
        ShowLoadingPanel(gContainer, 2, 'Saving attachment, please wait...');
        // #region Validate Inputs
        // Check Display Name
        if (CheckIfNoValue($('input[name="DisplayName"').val())) {
            $("div.attachmentError").removeAttr("hidden");
            DisplayFormError($('#DisplayNameError'), "<b>" + $("label[data-field='DisplayName']").text() + "</b> cannot be empty.", $('input[name="DisplayName"'));
            hasError = true;
        }
        else {
            if (checkFileExist($('input[name="DisplayName"').val())) {
                $("div.attachmentError").removeAttr("hidden");
                DisplayFormError($('#DisplayNameError'), "The selected file already exist. Please select another one or enter a different name.", $('input[name="DisplayName"'));
                hasError = true;
            }
            else {
                if ($('#DisplayNameError').attr("hidden") == undefined)
                    $('#DisplayNameError').attr("hidden", "hidden");
            }
        }
        //#endregion
        if (!hasError) {
            let fileName = $("input[name='DisplayName']").val();
            let fileFullName = $("#hidFileName").val();
            let fileExt = fileFullName.substring(fileFullName.lastIndexOf('.'));
            let attachmentItem = {
                requisitionAttachmentID: 0,
                requisitionID: 0,
                attachmentFileName: fileName.concat((new Date()).getTime().toString()).concat(fileExt),
                attachmentDisplayName: fileName,
                attachmentSize: GetIntValue($("input[name='FileSize']").val()),
                createdByEmpNo: gCurrentUser.empNo,
                createdBy: gCurrentUser.userName,
                createdDate: new Date(),
                fileName: fileName.replace(/\s+/g, ''),
                sequenceNo: attachmentArray.length + 1,
                base64File: $("#hidBase64File").val(),
                base64FileExt: fileExt
            };
            // Add item to the collection
            attachmentArray.push(attachmentItem);
            // Clear controls
            $("input[name='DisplayName']").val("");
            $("input[name='FileType']").val("");
            $("input[name='FileSize']").val("");
            // Setup button visibility            
            if ($("#btnAddAttachment").hasClass("disabled"))
                $("#btnAddAttachment").removeClass("disabled");
            $("#btnUpdateAttachment").addClass("disabled");
            $("#btnCancelAttachment").addClass("disabled");
            // Bind data tot table
            populateAttachmentTable(attachmentArray);
            // Remove the focus to all buttons
            $("div.attachmentButtons > button:focus").blur();
            // Clear the file upload
            $("#uploadFile").val("");
            // Show notification
            ShowToastMessage(toastTypes.success, "The selected file has been added successfully!", "Save Successful");
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while adding new attachment: " + "<b>" + error.message + "</b>");
    }
    finally {
        HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }
}
function deleteAttachment() {
    try {
        // Display loading panel
        gContainer = $('#attachmentTablePanel');
        ShowLoadingPanel(gContainer, 2, 'Deleting attachment, please wait...');
        let fileName = $(this).attr("data-filename");
        if (fileName.length > 0) {
            let isFound = false;
            let itemIndex = 0;
            // Find the index of the attachment item to delete
            attachmentArray.forEach(function (value, index) {
                if (value.fileName == fileName) {
                    itemIndex = index;
                    isFound = true;
                }
            });
            if (isFound) {
                // Remove the item from the array
                attachmentArray.splice(itemIndex, 1);
                // Bind data to table
                populateAttachmentTable(attachmentArray);
                // Show notification
                ShowToastMessage(toastTypes.success, "The selected file has been deleted successfully!", "Delete Successful");
            }
            else
                ShowToastMessage(toastTypes.error, "Unable to find the index of the selected file!", "Error");
        }
    }
    catch (error) {
        //ShowToastMessage(toastTypes.error, "Erro occured: " + "<b>" + error.message + "</b>", "Error");
        ShowErrorMessage("The following error has occured while deleting the selected attachment: " + "<b>" + error.message + "</b>");
    }
    finally {
        HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }
}
function downloadAttachment() {
    try {
        // Display loading panel
        gContainer = $('#attachmentTablePanel');
        ShowLoadingPanel(gContainer, 2, 'Downloading selected file, please wait...');
        let fileName = $(this).attr("data-filename");
        if (fileName.length > 0) {
            let isFound = false;
            let itemIndex = 0;
            // Find the index of the attachment item to delete
            attachmentArray.forEach(function (value, index) {
                if (value.fileName == fileName) {
                    itemIndex = index;
                    isFound = true;
                }
            });
            if (isFound) {
                // #region Download the file
                let selectedFile = attachmentArray[itemIndex];
                // Create the link object
                var a = document.createElement("a");
                var img = document.createElement("a");
                if (!CheckIfNoValue(selectedFile.base64File)) {
                    // #region Download file saved in the database
                    var base64Idx = selectedFile.base64File.indexOf(CONST_BASE64_KEY);
                    var base64String = selectedFile.base64File.slice(base64Idx + CONST_BASE64_KEY.length);
                    a.href = 'data:application/octet-stream;base64,' + base64String;
                    a.download = selectedFile.attachmentDisplayName.concat(selectedFile.base64FileExt);
                    a.click();
                    a.remove();
                    // Bind data to table
                    populateAttachmentTable(attachmentArray);
                    // Show notification
                    ShowToastMessage(toastTypes.info, "The selected file has been downloaded successfully!", "Download Successful");
                    // #endregion
                }
                else {
                    // #region Download file stored in the file system
                    let physicalName = selectedFile.attachmentFileName;
                    let downloadName = selectedFile.attachmentDisplayName.concat(selectedFile.base64FileExt);
                    var uri = "../../FileAttachments/".concat(physicalName);
                    a.href = uri;
                    a.setAttribute('download', downloadName);
                    // Check if url is valid and file exist in the file system
                    if (a.host && a.host != window.location.host) {
                        a.click();
                        a.remove();
                        // Refresh the table
                        populateAttachmentTable(attachmentArray);
                        // Show notification
                        ShowToastMessage(toastTypes.info, "The selected file has been downloaded successfully!", "Download Successful");
                    }
                    else {
                        // Refresh the table
                        populateAttachmentTable(attachmentArray);
                        // Show error notification
                        ShowToastMessage(toastTypes.error, "Could not find the selected file on the server!", "Download Failed");
                    }
                    // #endregion
                }
            }
            else
                ShowToastMessage(toastTypes.error, "Could not find the selected file on the server!", "Download Failed");
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while downloading the selected file: " + "<b>" + error.message + "</b>");
    }
    finally {
        HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }
}
function downloadLocalFile() {
    try {
        // Display loading panel
        gContainer = $('#attachmentTablePanel');
        ShowLoadingPanel(gContainer, 2, 'Downloading selected file, please wait...');
        let fileName = $(this).attr("data-filename");
        if (fileName.length > 0) {
            let isFound = false;
            let itemIndex = 0;
            // Find the index of the attachment item to delete
            attachmentArray.forEach(function (value, index) {
                if (value.fileName == fileName) {
                    itemIndex = index;
                    isFound = true;
                }
            });
            if (isFound) {
                // #region Download the file
                let selectedFile = attachmentArray[itemIndex];
                let physicalName = selectedFile.attachmentFileName;
                let downloadName = selectedFile.attachmentDisplayName.concat(selectedFile.base64FileExt);
                var uri = "../../FileAttachments/".concat(physicalName);
                // Create the hyperlink object
                var link = document.createElement("a");
                link.setAttribute('download', downloadName);
                link.href = uri;
                document.body.appendChild(link);
                link.click();
                link.remove();
                // Bind data to table
                populateAttachmentTable(attachmentArray);
                // Show notification
                ShowToastMessage(toastTypes.info, "The selected file has been downloaded successfully!", "Download Successful");
                // #endregion
            }
            else
                ShowToastMessage(toastTypes.error, "Could not download the selected file!", "Error");
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while deleting the selected attachment: " + "<b>" + error.message + "</b>");
    }
    finally {
        HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }
}
function checkFileExist(fileName) {
    if (attachmentArray.length == 0)
        return false;
    var newFileName = fileName.replace(/\s+/g, ''); // Remove spaces in the file name
    let isFound = false;
    if (fileName.length > 0) {
        // Find the index of the attachment 
        attachmentArray.forEach(function (value, index) {
            if (value.fileName == newFileName) {
                isFound = true;
            }
        });
    }
    return isFound;
}
function setActiveTab(tab) {
    switch (tab) {
        case TabType.RequestDetail:
            // #region Details tab
            // Set the active tab link
            if ($("#lnkAttachment").hasClass("active"))
                $("#lnkAttachment").removeClass("active");
            if ($("#lnkFinancial").hasClass("active"))
                $("#lnkFinancial").removeClass("active");
            $("#lnkDetail").addClass("active");
            // Set the active tab panel
            if ($("#tabAttachment").hasClass("active"))
                $("#tabAttachment").removeClass("active");
            $("#tabAttachment").addClass("fade");
            if ($("#tabFinancial").hasClass("active"))
                $("#tabFinancial").removeClass("active");
            $("#tabFinancial").addClass("fade");
            if ($("#tabDetail").hasClass("fade"))
                $("#tabDetail").removeClass("fade");
            $("#tabDetail").addClass("active");
            break;
        // #endregion
        case TabType.Financial:
            // #region Details tab
            // Set the active tab link
            if ($("#lnkDetail").hasClass("active"))
                $("#lnkDetail").removeClass("active");
            if ($("#lnkAttachment").hasClass("active"))
                $("#lnkAttachment").removeClass("active");
            $("#lnkFinancial").addClass("active");
            // Set the active tab panel
            if ($("#tabDetail").hasClass("active"))
                $("#tabDetail").removeClass("active");
            $("#tabDetail").addClass("fade");
            if ($("#tabAttachment").hasClass("active"))
                $("#tabAttachment").removeClass("active");
            $("#tabAttachment").addClass("fade");
            if ($("#tabFinancial").hasClass("fade"))
                $("#tabFinancial").removeClass("fade");
            $("#tabFinancial").addClass("active");
            break;
        // #endregion
        case TabType.FileAttachment:
            // #region File Attachment tab
            // Set the active tab link
            if ($("#lnkDetail").hasClass("active"))
                $("#lnkDetail").removeClass("active");
            if ($("#lnkFinancial").hasClass("active"))
                $("#lnkFinancial").removeClass("active");
            $("#lnkAttachment").addClass("active");
            // Set the active tab panel
            if ($("#tabDetail").hasClass("active"))
                $("#tabDetail").removeClass("active");
            $("#tabDetail").addClass("fade");
            if ($("#tabFinancial").hasClass("active"))
                $("#tabFinancial").removeClass("active");
            $("#tabFinancial").addClass("fade");
            if ($("#tabAttachment").hasClass("fade"))
                $("#tabAttachment").removeClass("fade");
            $("#tabAttachment").addClass("active");
            break;
        // #endregion
    }
}
function setModalTitle() {
    if (modalFormType == undefined)
        return;
    switch (modalFormType) {
        case ModalFormTypes.Delete:
            // #region Delete confirmation
            // Set the title of the modal form
            $("#modConfirmation .modalHeader").html("&nbsp;Warning");
            // Set the header background color
            if ($("#modConfirmation .modal-header").hasClass("bg-info"))
                $("#modConfirmation .modal-header").removeClass("bg-info");
            $("#modConfirmation .modal-header").addClass("bg-danger");
            // Set the icon of the modal form
            if ($("#modConfirmationIcon").hasClass("fa-times-circle"))
                $("#modConfirmationIcon").removeClass("fa-times-circle");
            $("#modConfirmationIcon").addClass("fa-exclamation-triangle");
            $(".modal-body > p").html("Deleting this requisition will also remove all related database records. Are you sure you want to <span class='text-dark fw-bold'>DELETE</span> this request?");
            break;
        // #endregion
        case ModalFormTypes.InvalidEstimatedCost:
            // #region Estimated Cost is greater than Balance Amount
            // Set the title of the modal form
            $("#modConfirmation .modalHeader").html("&nbsp;Request Additional Amount?");
            // Set the header background color
            if ($("#modConfirmation .modal-header").hasClass("bg-danger"))
                $("#modConfirmation .modal-header").removeClass("bg-danger");
            $("#modConfirmation .modal-header").addClass("bg-info");
            // Set the icon of the modal form
            if ($("#modConfirmationIcon").hasClass("fa-exclamation-triangle"))
                $("#modConfirmationIcon").removeClass("fa-exclamation-triangle");
            $("#modConfirmationIcon").addClass("fa-times-circle");
            $(".modal-body > p").html("The project estimated cost is greater than the project balance amount. Would you like to request for additional amount?");
            break;
        // #endregion
        case ModalFormTypes.RecallRequest:
            // #region Recall Requisition
            // Set the title of the modal form
            $("#modChangeStatus .modalHeader").html("&nbsp;Recall Requisition");
            // Set the message to be desplayed as notes
            $("#lblNotes").text("The user who has created the request, Cost Center Manager, or the System Administrator is allowed to recall this requisition.");
            break;
        // #endregion
        case ModalFormTypes.ReactivateRequest:
            // #region Reactivate Requisition
            // Set the title of the modal form
            $("#modChangeStatus .modalHeader").html("&nbsp;Re-activate Requisition");
            // Set the message to be desplayed as notes
            $("#lblNotes").text("Either the user who has rejected the request or the System Administrator is allowed to re-activate this requisition.");
            break;
        // #endregion
        case ModalFormTypes.ReopenRequest:
            // #region Reopen Requisition
            // Set the title of the modal form
            $("#modChangeStatus .modalHeader").html("&nbsp;Re-open Requisition");
            // Set the message to be desplayed as notes
            $("#lblNotes").text("Only the System Administrator is allowed to re-open this requisition.");
            break;
        // #endregion
        case ModalFormTypes.ReassignRequest:
            // #region Reassign Requisition
            // Set the title of the modal form
            $("#modReassignment .modalHeader").html("&nbsp;Reassign Approver");
            break;
        // #endregion
    }
}
function handleActionLink() {
    var btnAttrib = $(this).attr("data-button-value");
    switch (btnAttrib) {
        case ActionLinkTypes.ActionRecall:
            // #region Recall requisition
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update)) {
                // Set modal form type
                modalFormType = ModalFormTypes.RecallRequest;
                setModalTitle();
                // Show the change status box
                $("textarea[name='ChangeStatusComment']").val("");
                $("#modChangeStatus").modal("show");
            }
            else
                ShowToastMessage(toastTypes.error, CONST_RECALL_DENIED, "Access Denied");
            break;
        // #enregion
        case ActionLinkTypes.ActionReactivate:
            // #region Reactivate requisition
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update)) {
                // Set modal form type
                modalFormType = ModalFormTypes.ReactivateRequest;
                setModalTitle();
                // Show the change status box
                $("textarea[name='ChangeStatusComment']").val("");
                $("#modChangeStatus").modal("show");
            }
            else
                ShowToastMessage(toastTypes.error, CONST_RECALL_DENIED, "Access Denied");
            break;
        // #enregion
        case ActionLinkTypes.ActionReopen:
            // #region Reopen requisition
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update)) {
                // Set modal form type
                modalFormType = ModalFormTypes.ReopenRequest;
                setModalTitle();
                // Show the change status box
                $("textarea[name='ChangeStatusComment']").val("");
                $("#modChangeStatus").modal("show");
            }
            else
                ShowToastMessage(toastTypes.error, CONST_RECALL_DENIED, "Access Denied");
            break;
        // #enregion        
    }
}
function handleModalButtonClick() {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    var btnAttrib = $(this).attr("data-button-value");
    let hasError = false;
    if (btnAttrib == ModalResponseTypes.ModalYes) {
        // #region Yes modal button clicked
        modalResponse = ModalResponseTypes.ModalYes;
        switch (modalFormType) {
            case ModalFormTypes.Delete:
                // #region Delete draft request
                // Set the flag value
                $("input[name='ButtonActionType']").val(ButtonAction.Delete.toString());
                // Delete requisition
                insertUpdateDeleteRequisition(ButtonAction.Delete);
                // Show success message
                //ShowToastMessage(toastTypes.info, "Deletion process has been initiated for the selected requisition!", "Information");
                break;
            // #endregion
            case ModalFormTypes.InvalidEstimatedCost:
                // #region Estimated cost is greater than balance amount
                // Enable "Reason for Addition Amount" field
                $("textarea[name='ReasonForAdditionalAmt']").prop("disabled", false);
                $("textarea[name='ReasonForAdditionalAmt']").prop("required", true);
                // Show request for additional amount badge
                $("#lblAdditionalAmount").prop("hidden", false);
                // Set the flag
                isAdditionalAmt = true;
                break;
            // #endregion
        }
        // #endregion
    }
    else if (btnAttrib == ModalResponseTypes.ModalSave) {
        // #region Process recall, reactivation, and reopening of CEA requisition
        // Set modal response type
        modalResponse = ModalResponseTypes.ModalSave;
        let requisitionNo = (_a = $("input[name='RequisitionNo']").val()) === null || _a === void 0 ? void 0 : _a.toString();
        let empNo = GetIntValue($("input[name='UserEmpNo']").val());
        let comments = (_b = $("textarea[name='ChangeStatusComment']").val()) === null || _b === void 0 ? void 0 : _b.toString();
        // Check if justifications is supplied
        if (CheckIfNoValue(comments)) {
            showValidationError($('#ChangeStatusError'), "<b>" + $(".fieldLabel label[data-field='Justifications']").text() + "</b> cannot be empty!", $('textarea[name="ChangeStatusComment"]'));
            hasError = true;
        }
        else {
            if ($('#ChangeStatusError').attr("hidden") == undefined)
                $('#ChangeStatusError').attr("hidden", "hidden");
        }
        if (!hasError) {
            var actionType;
            if (modalFormType == ModalFormTypes.RecallRequest)
                actionType = ChangeStatusActionType.RecallRequest;
            else if (modalFormType == ModalFormTypes.ReactivateRequest)
                actionType = ChangeStatusActionType.ReactivateRequest;
            else if (modalFormType == ModalFormTypes.ReopenRequest)
                actionType = ChangeStatusActionType.ReopenRequest;
            // Hide the modal form
            $("#modChangeStatus").modal("hide");
            // Show loading panel
            ShowLoadingPanel(gContainer, 1, 'Recalling the requisition, please wait...');
            // Save to database
            changeRequestStatus(actionType, requisitionNo, empNo, comments);
        }
        // #endregion
    }
    else if (btnAttrib == ModalResponseTypes.ModalReassign) {
        // #region Process reassignment to another approver
        // Set modal response type
        modalResponse = ModalResponseTypes.ModalReassign;
        let requisitionNo = (_c = $("input[name='RequisitionNo']").val()) === null || _c === void 0 ? void 0 : _c.toString();
        let currentAssignedEmpNo = GetIntValue($("input[name='AssignedEmpNo']").val());
        let reassignedEmpNo = GetIntValue($("input[name='ReassignEmpNo']").val());
        let reassignedEmpName = (_d = $("input[name='ReassignEmpName']").val()) === null || _d === void 0 ? void 0 : _d.toString();
        let reassignedEmpEmail = (_e = $("input[name='ReassignEmpEmail']").val()) === null || _e === void 0 ? void 0 : _e.toString();
        let currentUserEmpNo = GetIntValue($("input[name='UserEmpNo']").val());
        let currentUserEmpName = (_f = $("input[name='UserName']").val()) === null || _f === void 0 ? void 0 : _f.toString();
        let routineSeq = 0;
        let onHold = false;
        let reason = (_g = $("textarea[name='ReassignReason']").val()) === null || _g === void 0 ? void 0 : _g.toString();
        let ceaDescription = (_h = $("input[name='RequisitionDescription']").val()) === null || _h === void 0 ? void 0 : _h.toString();
        // Check Reassigned Approver
        if (reassignedEmpNo == 0) {
            showValidationError($('#ReassignError'), "<b>" + "The new approver should be a valid employee!", $('input[name="ReassignEmpNo"]'));
            hasError = true;
        }
        else {
            if (currentAssignedEmpNo == reassignedEmpNo) {
                showValidationError($('#ReassignError'), "<b>" + "Cannot reassign to the same approver!", $('input[name="ReassignEmpNo"]'));
                hasError = true;
            }
            else {
                if ($('#ReassignError').attr("hidden") == undefined)
                    $('#ReassignError').attr("hidden", "hidden");
            }
        }
        // Check if justifications is supplied
        if (CheckIfNoValue(reason)) {
            showValidationError($('#ReassignReasonError'), "<b>" + $(".fieldLabel label[data-field='ReassignReason']").text() + "</b> cannot be empty!", $('textarea[name="ReassignReason"]'));
            hasError = true;
        }
        else {
            if ($('#ReassignReasonError').attr("hidden") == undefined)
                $('#ReassignReasonError').attr("hidden", "hidden");
        }
        if (!hasError) {
            // Hide the modal form
            $("#modReassignment").modal("hide");
            // Show loading panel
            ShowLoadingPanel(gContainer, 1, 'Reassigning the requisition, please wait...');
            // Initiate the reassignment process
            reassignRequest(requisitionNo, currentAssignedEmpNo, reassignedEmpNo, reassignedEmpName, reassignedEmpEmail, routineSeq, onHold, reason, currentUserEmpNo, currentUserEmpName, ceaDescription);
        }
        // #endregion
    }
    else if (btnAttrib == ModalResponseTypes.ModalNo)
        modalResponse = ModalResponseTypes.ModalNo;
    else if (btnAttrib == ModalResponseTypes.ModalCancel)
        modalResponse = ModalResponseTypes.ModalCancel;
}
// #endregion
// #region Database Methods
function getOriginatorList() {
    const searchFilter = new EmpSearchCriteria();
    searchFilter.empNo = 0;
    $.ajax({
        url: "/UserFunctions/Project/GetEmployeeList",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: searchFilter,
        success: function (response, status) {
            if (status == "success") {
                populateOriginatorList(response.data);
                // Display the Originator Name
                let orignatorName = $("#hidOriginatorEmpName").val();
                $("#txtOriginator").val(orignatorName);
            }
            else {
                throw new Error("Something went wrong while fethcing data data from the database!");
            }
        },
        error: function (err) {
            throw err;
        }
    });
}
function populateOriginatorList(data) {
    try {
        if (CheckIfNoValue(data))
            return;
        const empArray = [];
        const empArray2 = [];
        var item;
        for (var i = 0; i < data.length - 1; i++) {
            item = data[i];
            let empItem = {
                label: item.empNo + ", " + item.empName + ", " + item.email,
                value: item.empNo,
            };
            // Add object to array
            empArray.push(empItem);
            empArray2.push(empItem);
        }
        $("#txtOriginator").autocomplete({
            source: empArray,
            autoFocus: false,
            minLength: 2,
            delay: 300,
            select: function (event, ui) {
                if (ui.item != null && ui.item != undefined) {
                    // Save the employee details to the hidden fields
                    $("#hidOriginator").val(ui.item.value);
                    // Get the employee name
                    if (ui.item.label.length > 0) {
                        var empArray = ui.item.label.trim().split(",");
                        if (empArray != undefined) {
                            $("#txtOriginator").val(empArray[1].trim());
                            $("#hidOriginatorEmpName").val(empArray[1].trim());
                            $("#hidOriginator").val(empArray[0].trim());
                        }
                    }
                    // Hide missing approver error alert
                    $("#originatorValid").attr("hidden", "hidden");
                    return false;
                }
            },
            change: function (event, ui) {
                if (ui.item == undefined || ui.item == null) {
                    $("#hidOriginator").val("");
                    //showErrorCEAEntry($('#originatorValid'), "The specified employee does not exist.", $('#txtOriginator'));
                    $("#txtOriginator").focus();
                }
                else
                    $('#originatorValid').attr("hidden", "hidden");
                return false;
            }
        });
        $("#txtOriginator").autocomplete("enable");
        $("#txtReassignTo").autocomplete({
            source: empArray2,
            autoFocus: false,
            minLength: 2,
            delay: 300,
            select: function (event, ui) {
                if (ui.item != null && ui.item != undefined) {
                    // Save the employee details to the hidden fields
                    $("#hidReassignEmpNo").val(ui.item.value);
                    // Get the employee name
                    if (ui.item.label.length > 0) {
                        var empArray2 = ui.item.label.trim().split(",");
                        if (empArray2 != undefined) {
                            $("#txtReassignTo").val(empArray2[1].trim());
                            $("input[name='ReassignEmpNo']").val(empArray2[0].trim());
                            $("input[name='ReassignEmpName']").val(empArray2[1].trim());
                            $("input[name='ReassignEmpEmail']").val(empArray2[2].trim());
                        }
                    }
                    // Hide missing approver error alert
                    $("#ReassignError").attr("hidden", "hidden");
                    return false;
                }
            },
            change: function (event, ui) {
                if (ui.item == undefined || ui.item == null) {
                    $("input[name='ReassignEmpNo']").val("");
                    $("input[name='ReassignEmpName']").val("");
                    $("input[name='ReassignEmpEmail']").val("");
                    $("#txtReassignTo").focus();
                }
                else
                    $('#ReassignError').attr("hidden", "hidden");
                return false;
            }
        });
        $("#txtReassignTo").autocomplete("enable");
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured executing the populateEquipmentList() function: " + "<b>" + error.message + "</b>");
    }
}
function getEquipmentList() {
    $.ajax({
        url: "/UserFunctions/Project/GetEquipmentList",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        //data: searchFilter,
        success: function (response, status) {
            if (status == "success") {
                populateEquipmentList(response.data);
                populateEquipmentTable(response.data);
                // Display the Equipment No.
                let equipmentNo = $("#hidEquipmentNo").val();
                $("#txtEquipmentNo").val(equipmentNo);
            }
            else {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("Unable to load equipment list from the database, please contact ICT for technical support.");
            }
        },
        error: function (err) {
            HideLoadingPanel(gContainer);
            ShowErrorMessage("The following error has occured while executing getEquipmentList(): " + err.responseText);
        }
    });
}
function populateEquipmentList(data) {
    try {
        if (CheckIfNoValue(data))
            return;
        const equipmentArray = [];
        var item;
        // Add empty item
        //equipmentArray.push({
        //    label: " ",
        //    value: " ",
        //    parentEquipmentNo: "",
        //    parentEquipmentDesc: ""
        //});
        for (var i = 0; i < data.length - 1; i++) {
            item = data[i];
            let equipmentItem = {
                label: item.equipmentDesc,
                value: item.equipmentNo,
                parentEquipmentNo: item.parentEquipmentNo,
                parentEquipmentDesc: item.parentEquipmentDesc
            };
            // Add object to array
            equipmentArray.push(equipmentItem);
        }
        $("#txtEquipmentNo").autocomplete({
            source: equipmentArray,
            autoFocus: true,
            minLength: 2,
            delay: 300,
            select: function (event, ui) {
                if (ui.item != null && ui.item != undefined) {
                    // Get the equipment details
                    $("#hidEquipmentNo").val(ui.item.value);
                    $("#txtEquipmentNo").val(ui.item.value);
                    $('input[name="EquipmentDesc"]').val(ui.item.label);
                    $('input[name="EquipmentParentNo"]').val(ui.item.parentEquipmentNo);
                    $('input[name="EquipmentParentDesc"]').val(ui.item.parentEquipmentDesc);
                    // Hide missing equipment error alert
                    $("#EquipmentNoError").attr("hidden", "hidden");
                    return false;
                }
            },
            change: function (event, ui) {
                if (ui.item == undefined || ui.item == null) {
                    $("#hidEquipmentNo").val("");
                    showErrorCEAEntry($('#EquipmentNoError'), "The specified equipment does not exist.", $("#txtEquipmentNo"));
                    $("#txtEquipmentNo").focus();
                }
                else
                    $('#EquipmentNoError').attr("hidden", "hidden");
                return false;
            }
        });
        $("#txtEquipmentNo").autocomplete("enable");
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured executing the populateEquipmentList() method: " + "<b>" + error.message + "</b>");
    }
}
function populateEquipmentTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#equipmentTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "Schedule of Expense Report";
        $("#equipmentTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            orderMulti: false,
            destroy: true,
            scrollX: true,
            language: {
                emptyTable: "No expense records found."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[1, 'asc']],
            drawCallback: function () {
                $('.lnkEquipment').on('click', getEquipmentDetail);
            },
            dom: "<'row' <'col-sm-3'l> <'col-sm-6 text-center'> <'col-sm-3'f> >" +
                "<'row'<'col-sm-12 col-md-12'tr>>" +
                "<'row'<'col-xs-12 col-sm-5 col-md-5'i><'col-xs-12 col-sm-7 col-md-7'p>>",
            buttons: [
                {
                    text: '<i class="fas fa-file-excel fa-lg fa-fw"></i>',
                    extend: 'excel',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Export results to Excel',
                    title: reportTitle
                },
                {
                    text: '<i class="fas fa-file-csv fa-lg fa-fw"></i>',
                    extend: 'csv',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Export results to CSV',
                    title: reportTitle
                },
                {
                    text: '<i class="fas fa-print fa-lg fa-fw"></i>',
                    extend: 'print',
                    className: 'btn btn-light tableButton',
                    titleAttr: 'Print results'
                }
            ],
            columns: [
                {
                    data: null
                },
                {
                    data: "equipmentNo",
                    render: function (data) {
                        return '<label style="width: 100px;">' + data + '</label>';
                    }
                },
                {
                    data: "equipmentDesc",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "parentEquipmentNo",
                    render: function (data) {
                        return '<label style="width: 130px;">' + data + '</label>';
                    }
                },
                {
                    data: "parentEquipmentDesc",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                }
            ],
            columnDefs: [
                {
                    targets: 0,
                    render: function (data, type, row) {
                        return '<a class="btn btn-sm btn-primary text-white rounded-pill py-0 m-1 lnkEquipment" style="width: 105px;" data-equipmentno=' + row.equipmentNo + ' data-equipmentdesc=' + row.equipmentDesc + ' data-parentequipmentno=' + row.parentEquipmentNo + ' data-parentequipmentdesc=' + row.parentEquipmentDesc + '> ' +
                            '<span> <i class="fas fa-thumbs-up fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "Select" + '</a>' + '</label>';
                    }
                },
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                {
                    targets: "hiddenColumn",
                    visible: false
                },
                {
                    targets: "doNotOrder",
                    orderable: false
                }
            ]
        });
    }
}
function getEquipmentDetail() {
    let equipmentNo = $(this).attr("data-equipmentno");
    let equipmentDesc = $(this).attr("data-equipmentdesc");
    let parentEquipmentNo = $(this).attr("data-parentequipmentno");
    let parentEquipmentDesc = $(this).attr("data-parentequipmentdesc");
    if (!CheckIfNoValue(equipmentNo))
        $('#txtEquipmentNo').val(equipmentNo);
    if (!CheckIfNoValue(equipmentDesc))
        $('input[name="EquipmentDesc"]').val(equipmentDesc);
    if (!CheckIfNoValue(parentEquipmentNo))
        $('input[name="EquipmentParentNo"]').val(parentEquipmentNo);
    if (!CheckIfNoValue(parentEquipmentDesc))
        $('input[name="EquipmentParentDesc"]').val(parentEquipmentDesc);
    // Hide the modal form
    $("#modEquipment").modal("hide");
}
function insertUpdateDeleteRequisition(buttonAction) {
    let hasError = false;
    let errorTab = TabType.NotSet;
    try {
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
        if (buttonAction == ButtonAction.Draft || buttonAction == ButtonAction.Submit) {
            // Display loading panel
            ShowLoadingPanel(gContainer, 1, 'Submitting the request, please wait...');
            // #region Validate user input
            // Check Project No.
            if (CheckIfNoValue($('input[name="ProjectNo"').val())) {
                showValidationError($('#ProjectNoError'), "<b>" + $(".fieldLabel label[data-field='ProjectNo']").text() + "</b> cannot be empty!", $('input[name="ProjectNo"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#ProjectNoError').attr("hidden") == undefined)
                    $('#ProjectNoError').attr("hidden", "hidden");
            }
            // Check Item Type
            if (CheckIfNoValue($('select[name="CategoryCode1"').val())) {
                showValidationError($('#ItemTypeError'), "<b>" + $(".fieldLabel label[data-field='ItemType']").text() + "</b> cannot be empty!", $('select[name="CategoryCode1"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#ItemTypeError').attr("hidden") == undefined)
                    $('#ItemTypeError').attr("hidden", "hidden");
            }
            // Check Originator
            if (GetIntValue($('input[name="OriginatorEmpNo"').val()) == 0) {
                //showValidationError($('#OriginatorError'), "<b>" + $(".fieldLabel label[data-field='Originator']").text() + "</b> cannot be empty!", $('input[name="OriginatorEmpNo"]'));
                showValidationError($('#OriginatorError'), "<b>" + "Originator should be a valid employee!", $('input[name="OriginatorEmpNo"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#OriginatorError').attr("hidden") == undefined)
                    $('#OriginatorError').attr("hidden", "hidden");
            }
            // Check Requisition Description
            if (CheckIfNoValue($('input[name="RequisitionDescription"').val())) {
                showValidationError($('#RequisitionDescError'), "<b>" + $(".fieldLabel label[data-field='RequisitionDescription']").text() + "</b> cannot be empty!", $('input[name="RequisitionDescription"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#RequisitionDescError').attr("hidden") == undefined)
                    $('#RequisitionDescError').attr("hidden", "hidden");
            }
            // Check Item Required
            if (CheckIfNoValue($('textarea[name="Description"]').val())) {
                showValidationError($('#DescriptionError'), "<b>" + $(".fieldLabel label[data-field='Description']").text() + "</b> cannot be empty!", $('textarea[name="Description"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#DescriptionError').attr("hidden") == undefined)
                    $('#DescriptionError').attr("hidden", "hidden");
            }
            // Check Estimated Life Span
            let expenditureType = $('select[name="ExpenditureType"]').val();
            let estimatedLifeSpan = GetIntValue($('input[name="EstimatedLifeSpan"]').val());
            if (estimatedLifeSpan == 0 && expenditureType == "CEA") {
                showValidationError($('#EstimatedLifeSpanError'), "<b>" + $(".fieldLabel label[data-field='EstimatedLifeSpan']").text() + "</b> cannot be empty!", $('input[name="EstimatedLifeSpan"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#EstimatedLifeSpanError').attr("hidden") == undefined)
                    $('#EstimatedLifeSpanError').attr("hidden", "hidden");
            }
            // Check Account No.
            if (CheckIfNoValue($('input[name="AccountNo"').val())) {
                showValidationError($('#AccountNoError'), "<b>" + $(".fieldLabel label[data-field='AccountNo']").text() + "</b> cannot be empty!", $('input[name="AccountNo"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#AccountNoError').attr("hidden") == undefined)
                    $('#AccountNoError').attr("hidden", "hidden");
            }
            // Check Reason for Requisition
            if (CheckIfNoValue($('textarea[name="Reason"]').val())) {
                showValidationError($('#ReasonError'), "<b>" + $(".fieldLabel label[data-field='Reason']").text() + "</b> cannot be empty!", $('textarea[name="Reason"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#ReasonError').attr("hidden") == undefined)
                    $('#ReasonError').attr("hidden", "hidden");
            }
            // Check Date of Commision
            if (CheckIfNoValue($('input[name="DateofComission"]').val())) {
                showValidationError($('#DateofComissionError'), "<b>" + $(".fieldLabel label[data-field='DateofComission']").text() + "</b> cannot be empty!", $('input[name="DateofComission"]'));
                hasError = true;
                errorTab = TabType.RequestDetail;
            }
            else {
                if ($('#DateofComissionError').attr("hidden") == undefined)
                    $('#DateofComissionError').attr("hidden", "hidden");
            }
            // Check Estimated Cost
            let balanceAmount = GetFloatValue($('input[name="ProjectBalanceAmt"]').val());
            let estimatedCost = GetFloatValue($('input[name="RequestedAmt"]').val());
            let additionalAmount = GetFloatValue($('input[name="AdditionalBudgetAmt"]').val());
            if (estimatedCost == 0) {
                showValidationError($('#RequestedAmtError'), "<b>" + $(".fieldLabel label[data-field='RequestedAmt']").text() + "</b> is required and must be greater than zero!", $('input[name="RequestedAmt"]'));
                hasError = true;
                if (errorTab == TabType.NotSet)
                    errorTab = TabType.Financial;
            }
            else {
                // Check the Schedule of Expenses
                if (expenseArray.length == 0) {
                    $("div.expenseError").removeAttr("hidden");
                    DisplayFormError($('#SchedExpenseError'), "<b>Schedule of Expense</b> is required and must be equal to the Estimated Cost.", $('input[name="ExpenseAmount"]'));
                    hasError = true;
                    if (errorTab == TabType.NotSet)
                        errorTab = TabType.Financial;
                }
                else {
                    // Calculate the total amount
                    let totalAmount = 0;
                    expenseArray.forEach(function (value) {
                        totalAmount += value.amount;
                    });
                    // Check if total expenses equals to the estimated cost
                    if (totalAmount != estimatedCost) {
                        $("div.expenseError").removeAttr("hidden");
                        DisplayFormError($('#SchedExpenseError'), "The sum of <b>Schedule of Expenses (" + totalAmount.toString() + ")</b> is not equal to the <b>Estimated Cost (" + estimatedCost.toString() + ")</b>.", $('input[name="ExpenseAmount"]'));
                        hasError = true;
                        if (errorTab == TabType.NotSet)
                            errorTab = TabType.Financial;
                    }
                    else {
                        // Check if additional amount flag is turned on
                        if (isAdditionalAmt) {
                            // Check if "Reason for Additional Amount" field is supplied
                            if (CheckIfNoValue($('textarea[name="ReasonForAdditionalAmt"]').val())) {
                                showValidationError($('#ReasonAddAmtError'), "<b>" + $(".fieldLabel label[data-field='ReasonForAdditionalAmt']").text() + "</b> cannot be empty!", $('textarea[name="ReasonForAdditionalAmt"]'));
                                hasError = true;
                                if (errorTab == TabType.NotSet)
                                    errorTab = TabType.Financial;
                            }
                            else {
                                if ($('#ReasonAddAmtError').attr("hidden") == undefined)
                                    $('#ReasonAddAmtError').attr("hidden", "hidden");
                            }
                        }
                        else {
                            // Check if estimated cost is greater than balance amount
                            if (estimatedCost > balanceAmount) {
                                // Set the modal header title
                                modalFormType = ModalFormTypes.InvalidEstimatedCost;
                                setModalTitle();
                                // Set the error flag
                                hasError = true;
                                if (errorTab == TabType.NotSet)
                                    errorTab = TabType.Financial;
                                // Show the confirmation box
                                $("#modConfirmation").modal("show");
                            }
                        }
                    }
                }
            }
            // #endregion
        }
        else if (buttonAction == ButtonAction.Delete) {
            // Display loading panel
            ShowLoadingPanel(gContainer, 1, 'Deleting requisition, please wait...');
        }
        if (!hasError) {
            setActiveTab(selectedTab);
            // Invoke the post submit action method
            $("#btnHiddenSubmit").click();
            // Display loading panel
            ShowLoadingPanel(gContainer, 1, 'Submitting the request, please wait...');
        }
        else {
            setActiveTab(errorTab);
            HideLoadingPanel(gContainer);
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while saving or deleting the requisition: " + "<b>" + error.message + "</b>");
    }
    finally {
        //HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }
}
function changeRequestStatus(actionType, requisitionNo, empNo, comments) {
    var currentActionType;
    var successNotification = "";
    switch (actionType) {
        case ChangeStatusActionType.RecallRequest:
            currentActionType = ChangeStatusActionType.RecallRequest;
            successNotification = "Requisition No. " + requisitionNo + " has been recalled successfully";
            break;
        case ChangeStatusActionType.ReactivateRequest:
            currentActionType = ChangeStatusActionType.ReactivateRequest;
            successNotification = "Requisition No. " + requisitionNo + " has been reactivated successfully";
            break;
        case ChangeStatusActionType.ReopenRequest:
            currentActionType = ChangeStatusActionType.ReopenRequest;
            successNotification = "Requisition No. " + requisitionNo + " has been re-opened successfully";
            break;
    }
    let param = {
        requisitionNo: requisitionNo,
        actionType: currentActionType,
        empNo: empNo,
        wfInstanceID: GetStringValue($("input[name='WorkflowID']").val()),
        comments: comments
    };
    $.ajax({
        url: "/UserFunctions/Project/ChangeRequisitionStatus",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: param,
        success: function (response, status) {
            if (status == "success") {
                var dbResult = response.data;
                if (dbResult.hasError) {
                    if (!CheckIfNoValue(dbResult.errorDesc)) {
                        // Show error message
                        //ShowToastMessage(toastTypes.error, dbResult.errorDesc, "Error Occured");
                        ShowErrorMessage(dbResult.errorDesc);
                        // Hide loading panel
                        HideLoadingPanel(gContainer);
                    }
                }
                else {
                    HideLoadingPanel(gContainer);
                    // Open the Requisition Inquiry view
                    location.href = "/UserFunctions/Project/RequisitionInquiry?callerForm=".concat(PageControllerMapping.CEARequisition.toString())
                        .concat("&invoke_search=true")
                        .concat("&toastmsg=").concat(successNotification);
                }
            }
            else {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("Unable to change the requisition status due to unknown error. Please contact ICT!");
            }
        },
        error: function (err) {
            HideLoadingPanel(gContainer);
            ShowErrorMessage("The following error has occured while changing the status of the requisition: " + err.responseText);
        }
    });
}
function reassignRequest(requisitionNo, currentAssignedEmpNo, reassignedEmpNo, reassignedEmpName, reassignedEmpEmail, routineSeq, onHold, reason, currentUserEmpNo, currentUserEmpName, ceaDescription) {
    var successNotification = "Requisition No. " + requisitionNo + " has been reassigned to " + reassignedEmpName + " successfully";
    let param = {
        requisitionNo: requisitionNo,
        currentAssignedEmpNo: currentAssignedEmpNo,
        reassignedEmpNo: reassignedEmpNo,
        reassignedEmpName: reassignedEmpName,
        reassignedEmpEmail: reassignedEmpEmail,
        routineSeq: routineSeq,
        onHold: onHold,
        reason: reason,
        wfInstanceID: GetStringValue($("input[name='WorkflowID']").val()),
        reassignedBy: currentUserEmpNo,
        reassignedName: currentUserEmpName,
        ceaDescription: ceaDescription
    };
    $.ajax({
        url: "/UserFunctions/Project/ReassignRequisition",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: param,
        success: function (response, status) {
            if (status == "success") {
                var dbResult = response.data;
                if (dbResult.hasError) {
                    if (!CheckIfNoValue(dbResult.errorDesc)) {
                        // Show error message
                        ShowErrorMessage(dbResult.errorDesc);
                        // Hide loading panel
                        HideLoadingPanel(gContainer);
                    }
                }
                else {
                    HideLoadingPanel(gContainer);
                    // Open the Requisition Inquiry view
                    location.href = "/UserFunctions/Project/RequisitionInquiry?callerForm=".concat(PageControllerMapping.CEARequisition.toString())
                        .concat("&invoke_search=true")
                        .concat("&toastmsg=").concat(successNotification);
                }
            }
            else {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("Unable to reassign the requisition due to an unknown error. Please contact ICT!");
            }
        },
        error: function (err) {
            HideLoadingPanel(gContainer);
            ShowErrorMessage("The following error has occured when reassigning this CEA requisition: " + err.responseText);
        }
    });
}
// #endregion
// #region Workflow Methods
function beginApprovalProcess(isApprove) {
    let hasError = false;
    let errorTab = TabType.RequestDetail;
    let msgToShow = "";
    let approverRemarks = "";
    let requisitionNo = "";
    try {
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
        // Get the parameter values
        requisitionNo = GetStringValue($('input[name="RequisitionNo"]').val());
        approverRemarks = GetStringValue($('textarea[name="ApproverComments"]').val());
        if (isApprove)
            msgToShow = "Approving the request, please wait...";
        else
            msgToShow = "Rejecting the request, please wait...";
        // Check Approver Remarks
        if (CheckIfNoValue(approverRemarks) && !isApprove) {
            showValidationError($('#ApproverCommentsError'), "<b>" + $(".fieldLabel label[data-field='ApproverComments']").text() + "</b> is required when rejecting the request!", $('textarea[name="ApproverComments"]'));
            hasError = true;
            errorTab = TabType.RequestDetail;
        }
        else {
            if ($('#ApproverCommentsError').attr("hidden") == undefined)
                $('#ApproverCommentsError').attr("hidden", "hidden");
        }
        if (!hasError) {
            // Display loading panel
            ShowLoadingPanel(gContainer, 2, msgToShow);
            setActiveTab(TabType.RequestDetail);
            // Execute the approva/rejection process
            approveRejectRequest(requisitionNo, isApprove, gCurrentUser.empNo, gCurrentUser.empName, approverRemarks);
        }
        else {
            setActiveTab(TabType.RequestDetail);
            //HideLoadingPanel(gContainer);
        }
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while approving or rejecting the requisition: " + "<b>" + error.message + "</b>");
    }
    finally {
        //HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }
}
function approveRejectRequest(requisitionNo, isApproved, approverEmpNo, approverEmpName, approverRemarks) {
    var successNotification = isApproved == true ? "Requisition No. " + requisitionNo + " has been approved successfully" : "Requisition No. " + requisitionNo + " has been rejected successfully";
    let param = {
        requisitionNo: requisitionNo,
        wfInstanceID: GetStringValue($("input[name='WorkflowID']").val()),
        appRole: isApproved == true ? UserActionType.ApproveRequest : UserActionType.RejectRequest,
        appRoutineSeq: GetIntValue($("input[name='WFRoutineSequence']").val()),
        appApproved: isApproved,
        appRemarks: approverRemarks,
        approvedBy: approverEmpNo,
        approvedName: approverEmpName,
        statusCode: isApproved == true ? CEAStatusCode.Approved : CEAStatusCode.Rejected
    };
    $.ajax({
        url: "/UserFunctions/Project/ApproveRejectRequest",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: param,
        success: function (response, status) {
            if (status == "success") {
                var dbResult = response.data;
                if (dbResult.hasError) {
                    if (!CheckIfNoValue(dbResult.errorDesc)) {
                        // Show error message
                        ShowErrorMessage(dbResult.errorDesc);
                        // Hide loading panel
                        HideLoadingPanel(gContainer);
                    }
                }
                else {
                    HideLoadingPanel(gContainer);
                    // Open the Requisition Inquiry view
                    location.href = "/UserFunctions/Project/RequisitionInquiry?callerForm=".concat(PageControllerMapping.CEARequisition.toString())
                        .concat("&invoke_search=true")
                        .concat("&toastmsg=").concat(successNotification);
                }
            }
            else {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("Unable to completed the approval process due to an unknown error. Please contact ICT!");
            }
        },
        error: function (err) {
            HideLoadingPanel(gContainer);
            ShowErrorMessage("The following error has occured while executing approveRejectRequest() function: " + err.responseText);
        }
    });
}
// #endregion
//# sourceMappingURL=ceaRequest.js.map