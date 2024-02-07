var container;
$(() => {
    // Set the current container
    gContainer = $('.formWrapper');
    ShowLoadingPanel(container, 2, 'Loading data...');
    //loading data while page load
    LoadAdminDataTable();
    const button = document.getElementById('btnSearch');
    button === null || button === void 0 ? void 0 : button.addEventListener('click', function handleClick(event) {
        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");
        $('#btnSearch').attr("disabled", "disabled");
        container = $('.gridWrapper');
        ShowLoadingPanel(container, 2, 'Loading data...');
        LoadAdminDataTable();
    });
    $("#requisitionTable")
        .on('init.dt', function () {
        HideLoadingPanel(gContainer);
    })
        .DataTable({
        "language": {
            "emptyTable": "No data available"
        }
    });
    // #region Initialize form secuity
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());
    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential);
        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.RequestAdmin);
        $("#hidUserId").val(model.empNo);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.RequestAdmin);
    }
    // #endregion
    $("#btnReset").on('click', handleResetButtonClick);
});
// #region Database Access Methods
function LoadAdminDataTable() {
    try {
        let CostCenter = $("#cmbCostCenter").val().toString();
        let ExpenditureType = $("#cmbExpenditureType").val().toString();
        let FiscalYear = isNaN(parseInt($("#cmbFiscalYear").val().toString())) ? 0 : parseInt($("#cmbFiscalYear").val().toString());
        let ProjectNo = $("#txtProjectNo").val().toString();
        let RequisitionStatus = $("#cmbRequisitionStatus").val().toString() == '' ? "" : $("#cmbRequisitionStatus").val().toString();
        let Keywords = $("#txtKeyword").val().toString();
        let txtRequisitionNo = $("#txtRequisitionNo").val().toString();
        $.ajax({
            url: "/AdminFunctions/Admin/LoadRequisition",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: {
                costCenter: CostCenter,
                expenditureType: ExpenditureType,
                fiscalYear: FiscalYear,
                projectNo: ProjectNo,
                requisitionStatus: RequisitionStatus,
                requisitionNo: txtRequisitionNo,
                keywords: Keywords,
            },
            success: function (response, status) {
                if (status == "success") {
                    PopulateAdminDataTable(response.data);
                }
                else {
                    throw new Error("Something went wrong while fethcing data from the database !");
                }
            },
            error: function (err) {
                HideLoadingPanel(container);
                throw err;
            }
        });
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>");
    }
}
function openRequisition() {
    let reqNo = $(this).text().trim();
    let actionType = 0;
    //let assignedToEmpNo = GetIntValue($(this).attr("data-assignedtoempno"));
    //let currentUserEmpNo = GetIntValue($("#hidEmpNo").val()!.toString());
    ShowLoadingPanel(gContainer, 1, 'Loading requisition details, please wait...');
    // Open the Project Details View
    location.href = "/UserFunctions/Project/CEARequisition?requisitionNo=".concat(reqNo)
        .concat("&actionType=").concat(actionType.toString())
        .concat("&user_empno=").concat(gUserAccess.empNo.toString())
        .concat("&user_empname=").concat(gUserAccess.empName.trim())
        .concat("&callerForm=").concat(PageControllerMapping.RequisitionAdmin.toString());
}
function PopulateAdminDataTable(data) {
    gContainer = $('.gridWrapper');
    var dataset = data.result;
    console.log(dataset);
    if (data == null || data === undefined) {
        // Get DataTable API instance
        var table = $("#requisitionTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
        return;
    }
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#requisitionTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
    }
    else {
        $("#requisitionTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
            // Reset the buttons
            $('#btnSearch').removeAttr("disabled");
            $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
            $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            //filter: true,               // To enable/disable filter (search box)
            orderMulti: false,
            destroy: true,
            scrollX: true,
            //sScrollX: "100%",
            //sScrollXInner: "110%",      // This property can be used to force a DataTable to use more width than it might otherwise do when x-scrolling is enabled.
            language: {
                emptyTable: "No records found in the database."
            },
            //width: "100%",
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[0, 'desc']],
            drawCallback: function () {
                $('.lnkReqNo').on('click', openRequisition);
            },
            columns: [
                {
                    data: "requisitionNo",
                    name: "Requisition No.",
                    render: function (data, type, row, meta) {
                        //let Url = '/UserFunctions/Project/CEARequisition/' + row.requisitionNo;
                        //return '<label style="width: 120px;">' + '<a class="lnkReqNo gridLink" style="color: red; font-size: 14px;" href=' + Url + ' class="lnkClaimNo gridLink" data-requisitionno=' + row.requisitionNo + '> ' +
                        //    data + '</a>' + '</label>';
                        return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkReqNo gridLink" style="color: red; font-size: 14px;" data-requisitionno=' + row.requisitionNo + ' data-assignedtoempno=' + row.assignedToEmpNo + '> ' + row.requisitionNo + '</a>' + '</label>';
                    }
                },
                {
                    data: "requestDate",
                    name: "Requisition Date",
                    render: function (data, type, row, meta) {
                        return '<label style="width: 150px;">' + moment(row.requestDate).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: "requisitionDescription",
                    name: "Description"
                },
                {
                    data: "ceaStatusDesc",
                    name: "Status",
                },
                {
                    data: "requestedAmt",
                    name: "Amount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                //{
                //    data: "statusCodeMsg",
                //    name: "Action",
                //    render: function (data, type, row) {
                //        return '<button type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + + row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.statusCode + '\') ">' + data + '</button>';
                //        }
                //},
                {
                    data: "statusHandlingCode",
                    name: "Action",
                },
                {
                    data: "projectBalanceAmt",
                    name: "Used Amount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                {
                    targets: [0, 1, 3, 5],
                    className: 'dt-body-center',
                },
                {
                    targets: [4, 6],
                    className: "dt-body-right",
                },
                {
                    targets: 2,
                    render: function (data, type, row) {
                        if (data.length > 0)
                            return data.substr(0, 35) + '...';
                        else
                            return null;
                    }
                },
                {
                    targets: 5,
                    render: function (data, type, row) {
                        //if (row.statusCode == 'AwaitingChairmanApproval') {
                        //    return '<button class="btn btn-sm btn-primary rounded-pill text-white my-1 lnkStatus" style="width: 230px;" type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + + row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.statusCode + '\') ">' + 'Chairman Approved' + '</button>';
                        //}
                        //else if (row.statusCode == 'Approved') {
                        //    return '<button class="btn btn-sm btn-success rounded-pill text-white my-1 lnkStatus" style="width: 230px;" type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + + row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.statusCode + '\') ">' + 'Upload to OneWorld' + '</button>';
                        //}
                        //else if (row.statusCode == 'UploadedToOneWorld') {
                        //    return '<button class="btn btn-sm btn-secondary rounded-pill text-white my-1 lnkStatus" style="width: 230px;" type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + + row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.statusCode + '\') ">' + 'Close Requisition' + '</button>';
                        //}
                        //else {
                        //    return null;
                        //}
                        if (row.ceaStatusCode == 'AwaitingChairmanApproval') {
                            return '<button class="btn btn-sm btn-primary rounded-pill text-white my-1 lnkStatus" style="width: 230px;" type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + +row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.ceaStatusCode + '\') ">' + 'Chairman Approved' + '</button>';
                        }
                        else if (row.ceaStatusCode == 'Approved') {
                            return '<button class="btn btn-sm btn-success rounded-pill text-white my-1 lnkStatus" style="width: 230px;" type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + +row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.ceaStatusCode + '\') ">' + 'Upload to OneWorld' + '</button>';
                        }
                        else if (row.ceaStatusCode == 'UploadedToOneWorld') {
                            return '<button class="btn btn-sm btn-secondary rounded-pill text-white my-1 lnkStatus" style="width: 230px;" type="button" onclick= "UploadToOneWorld(' + row.requisitionId + ', ' + row.requisitionNo + ', ' + +row.companyCode + ', ' + row.costCenter + ', ' + row.objectCode + ', ' + row.subjectCode + ', ' + row.accountCode + ', ' + row.requestedAmt + ',\'' + row.ceaStatusCode + '\') ">' + 'Close Requisition' + '</button>';
                        }
                        else {
                            return null;
                        }
                    }
                }
            ]
        });
    }
}
function UploadToOneWorld(requisitionId, requisitionNo, companyCode, costCenter, objectCode, subjectCode, accountCode, requisitionAmount, status) {
    try {
        var userID = $("#hidUserId").val();
        if (objectCode == null && subjectCode == null && accountCode == null && status == "Approved") {
            ShowErrorMessage("Unable to upload to OneWorld without objectCode, subjectCode, and accountCode being empty!");
        }
        else {
            // clearing any error messge exists
            handleResetButtonClick();
            if (status == 'Approved')
                ShowLoadingPanel(gContainer, 1, 'Uploading data to the OneWorld and sending notification mails to all the approvers, please wait...');
            else if (status == 'UploadedToOneWorld')
                ShowLoadingPanel(gContainer, 1, 'Closing the requisition, please wait...');
            else if (status == 'AwaitingChairmanApproval')
                ShowLoadingPanel(gContainer, 1, 'Redirecting to the CEARequisition, please wait...');
            else { }
            //location.href = "/AdminFunctions/Admin/UploadToOneWorld?requisitionID=".concat(requisitionId).concat("&requisitionNo=").concat(requisitionNo)
            //    .concat("&companyCode=").concat(companyCode).concat("&costCenter=").concat(costCenter).concat("&objectCode=").concat(objectCode).concat("&subjectCode=")
            //    .concat(subjectCode).concat("&accountCode=").concat(accountCode).concat("&requisitionAmount=").concat(requisitionAmount).concat("&status=").concat(status);
            $.ajax({
                url: "/AdminFunctions/Admin/UploadToOneWorld",
                type: "GET",
                dataType: "json",
                contentType: "application/json; charset=utf-8",
                cache: false,
                async: true,
                data: {
                    requisitionID: requisitionId,
                    requisitionNo: requisitionNo,
                    companyCode: companyCode,
                    costCenter: costCenter,
                    objectCode: objectCode,
                    subjectCode: subjectCode,
                    accountCode: accountCode,
                    requisitionAmount: requisitionAmount,
                    status: status,
                    userID: userID
                },
                success: function (response, status) {
                    if (status == "success") {
                        // Show notification
                        ShowToastMessage(toastTypes.success, "Requisition Updated into the OneWorld", "Upload to OneWorld");
                        ShowLoadingPanel(container, 2, 'Loading data...');
                        //loading data while page load
                        LoadAdminDataTable();
                    }
                    else {
                        console.log("failure Part");
                        throw new Error("Something went wrong while fethcing data from the database !");
                    }
                },
                error: function (err) {
                    console.log("error Part");
                    console.log(err);
                    throw err;
                }
            });
        }
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>");
    }
}
function handleResetButtonClick() {
    // Hide error alerts
    $('.errorMsgBox').attr("hidden", "hidden");
    $('.errorPanel').attr("hidden", "hidden");
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
    $("#btnHiddenReset").click();
}
//# sourceMappingURL=RequisitionAdmin.js.map