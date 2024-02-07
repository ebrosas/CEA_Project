var container;
$(() => {
    // Set the current container
    container = $('.gridWrapper');
    //ShowLoadingPanel(container, 1, 'Loading data...');
    $('#requisitionPendingTable').DataTable({
        "language": {
            "emptyTable": "No records found in the database."
        }
    });
    //LoadDataTable();
    LoadEquipmentNoDataTable();
    const button = document.getElementById('btnSave');
    button === null || button === void 0 ? void 0 : button.addEventListener('click', function handleClick(event) {
        container = $('.gridWrapper');
        ShowLoadingPanel(container, 2, 'Loading data...');
        SaveEquipmentNo();
    });
    const buttonBack = document.getElementById('btnBack');
    buttonBack === null || buttonBack === void 0 ? void 0 : buttonBack.addEventListener('click', function handleClick(event) {
        $.ajax({
            url: "/AdminFunctions/Admin/ManageEquipmentNo",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: {},
            success: function () { },
        });
    });
    const btnSearch = document.getElementById('btnSearch');
    btnSearch === null || btnSearch === void 0 ? void 0 : btnSearch.addEventListener('click', function handleClick(event) {
        // Disable the search button
        $('#btnSearch').attr("disabled", "disabled");
        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");
        container = $('.gridWrapper');
        ShowLoadingPanel(container, 2, 'Loading data...');
        LoadDataTable();
    });
    // #region Initialize form secuity
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());
    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential);
        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.EquipmentAssignment);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.EquipmentAssignment);
    }
    // #endregion
    // loading data while the page loads
    //var url = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    //if (url[1] == undefined) {
    //    container = $('.gridWrapper');
    //    ShowLoadingPanel(container, 2, 'Loading data...');
    //    LoadDataTable();
    //}
    // loading the requistion based on the condition
    var url = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for (var i = 0; i < url.length; i++) {
        var urlparam = url[i].split('=');
        let val = urlparam[1];
        if (val == undefined) {
            container = $('.gridWrapper');
            ShowLoadingPanel(container, 2, 'Loading data...');
            LoadDataTable();
        }
        else if (val == 'success') {
            ShowToastMessage(toastTypes.success, "Equipment number is updated for selected requisition", "Equipment Number Saved");
            container = $('.gridWrapper');
            ShowLoadingPanel(container, 2, 'Loading data...');
            LoadDataTable();
        }
    }
    // Adjust the table column size when showing the modal form
    $('#addEquipmentNoDialog').on('shown.bs.modal', function () {
        var table = $('#EquipmentNoAssignTable').DataTable();
        table.columns.adjust();
    });
});
/*not using*/
function theFunction(accountNo, requisitionNo, estimatedLifeSpan, requestedAmt, description, reason) {
    document.getElementById("txtEstimatedCost").value = requestedAmt;
    document.getElementById("txtReasonRequisition").value = description;
    document.getElementById("txtLifeSpan").value = estimatedLifeSpan;
    document.getElementById("txtItemRequired").value = reason;
    document.getElementById("txtAccountNo").value = accountNo;
    document.getElementById("txtRequisitionNo").value = requisitionNo;
}
// #region Database Access Methods
function LoadDataTable() {
    try {
        let CostCenter = $("#CostCenterId").val().toString();
        let ExpenditureType = $("#ExpenditureTypeId").val().toString();
        let ProjectNo = $("#txtProjectNo").val().toString();
        let txtRequisitionNo = $('#txtRequisitionNo').val().toString();
        //let FromFiscalYear = $('#FormFiscalYearId').val()!.toString();
        //let ToFiscalYear = $('#ToFiscalYearId').val()!.toString();
        let FromFiscalYear = $('#cboFiscalYear').val().toString();
        let ToFiscalYear = null;
        $.ajax({
            url: "/AdminFunctions/Admin/LoadManageEquipmentNo",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: {
                costCenter: CostCenter,
                expenditureType: ExpenditureType,
                projectNo: ProjectNo,
                requisitionNo: txtRequisitionNo,
                fromFiscalYear: FromFiscalYear,
                toFiscalYear: ToFiscalYear
            },
            success: function (response, status) {
                if (status == "success") {
                    console.log(response.data);
                    PopulateDataTable(response.data);
                }
                else {
                    throw new Error("Something went wrong while fethcing data from the database !");
                }
            },
            error: function (err) {
                throw err;
            }
        });
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>");
    }
}
function PopulateDataTable(data) {
    gContainer = $('.gridWrapper');
    var dataset = data.result;
    if (data == null || data === undefined) {
        // Get DataTable API instance
        var table = $("#requisitionPendingTable").dataTable().api();
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
        var table = $("#requisitionPendingTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
        return;
    }
    else {
        $("#requisitionPendingTable")
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
            language: {
                emptyTable: "No records found in the database."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[1, 'desc']],
            columns: [
                {
                    data: "requisitionNo",
                    name: "",
                    //render: function (data) {
                    //    let Url = '/AdminFunctions/Admin/ManageEquipmentNo/' + data;
                    //    return '<label style="width: 120px; font-size: 12px;">' + '<a class="w-100 p-0 m-0" onclick="return theFunction( '+ data + ');" class="lnkClaimNo gridLink" data-projectno=' + data + '> ' +
                    //        'Select' + '</a>' + '</label>';
                    //}
                    //render: function (data, type, row, meta) {
                    //    let Url = '/AdminFunctions/Admin/ManageEquipmentNoEdit/' + row.requisitionNo;
                    //    return '<label style="width: 160px; font-size: 12px;">' + '<a class="w-100 p-0 m-0"   href="'+ Url +'" class="lnkClaimNo gridLink" data-projectno=' + row.requisitionNo + '> ' +
                    //        data + '</a>' + '</label>';
                    //}
                    //render: function (data, type, row, meta) {
                    //    /*let Url = '/AdminFunctions/Admin/ManageEquipmentNoEdit/' + row.requisitionNo;*/
                    //    return '<label style="width: 160px; font-size: 12px;">' + '<a class="w-100 p-0 m-0"   onclick="return LoadEquipmentAssignment( ' + data + ');"  class="lnkClaimNo gridLink" data-projectno=' + row.requisitionNo + '> ' +
                    //        data + '</a>' + '</label>';
                    //}
                    render: function (data, type, row, meta) {
                        return '<label style="width: 160px; font-size: 12px;">' + '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 lnkEmpNo"   onclick="return LoadEquipmentAssignment( ' + data + ');"  data-projectno=' + row.requisitionNo + '> ' +
                            '<span> <i class="fas fa-thumbs-up fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "Select" + '</a>' + '</label>';
                    }
                },
                {
                    data: "projectNo",
                    name: "Project No.",
                },
                {
                    data: "requisitionNo",
                    name: " Requisition No."
                },
                {
                    data: "expenditureType",
                    name: "Expenditure Type",
                },
                {
                    data: "equipmentNo",
                    name: "Equipment No"
                },
                {
                    data: "requisitionDescription",
                    name: "Description",
                },
                {
                    data: "requestedAmt",
                    name: "Requested Amount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                {
                    targets: [0, 1, 2, 3],
                    className: 'dt-body-center',
                },
                {
                    targets: [4, 6],
                    className: "dt-body-right",
                    createdCell: function (td, cellData, rowData, row, col) {
                        $(td).css('padding', '10px');
                    }
                },
                {
                    targets: [5],
                    render: function (data, type, row) {
                        if (data.length > 0)
                            return data.substr(0, 35) + '...';
                        else
                            return null;
                    }
                },
            ]
        });
    }
}
//-------------------equpment no page
function SetAssignNo(EquipmentNo, ParentEquipmentNo, equipDescription, ParentDescription) {
    document.getElementById("txtEquipmentNo").value = EquipmentNo;
    document.getElementById("txtEquipmentParentNo").value = ParentEquipmentNo;
    document.getElementById("txtEquipmentDescription").value = unescape(equipDescription) != 'null' ? unescape(equipDescription) : '';
    document.getElementById("txtEquipmentParentDesc").value = unescape(ParentDescription) != 'null' ? unescape(ParentDescription) : '';
    //$('#addEquipmentNoDialog').fadeOut(500);
    $("#addEquipmentNoDialog .btn-close").click().fadeOut(1000);
}
function LoadEquipmentNoDataTable() {
    try {
        $.ajax({
            url: "/AdminFunctions/Admin/LoadEquipmentNo",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: {},
            success: function (response, status) {
                if (status == "success") {
                    PopulateEquipmentNoDataTable(response.data);
                    /*                        window.opener.disableBackground();*/
                }
                else {
                    throw new Error("Something went wrong while fethcing data from the database !");
                }
            },
            error: function (err) {
                throw err;
            }
        });
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>");
    }
}
function PopulateEquipmentNoDataTable(data) {
    console.log("PopulateEquipmentNoDataTable");
    console.log(data);
    gContainer = $('.gridWrapper');
    var dataset = data.result;
    if (data == null || data === undefined) {
        // Get DataTable API instance
        var table = $("#EquipmentNoAssignTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
        return;
    }
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#EquipmentNoAssignTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        $("#EquipmentNoAssignTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            //filter: true,               // To enable/disable filter (search box)
            orderMulti: false,
            destroy: true,
            scrollX: true,
            language: {
                emptyTable: "No records found in the database."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[1, 'desc']],
            fixedHeader: true,
            columns: [
                {
                    data: "equipmentNo",
                    name: "",
                    render: function (data, type, row, meta) {
                        let equipmentDesc = escape(row.equipmentDescription); // removing wild characters
                        let ParentDesc = escape(row.equipmentParentDescription); // removing wild characters
                        return '<label style="width: 100px; font-size: 10px;">' + '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 lnkEmp"  onclick="SetAssignNo(\'' + row.equipmentNo + '\',\'' + row.equipmentParentNo + '\',\'' + equipmentDesc + '\',\'' + ParentDesc + '\');"  data-projectno=' + row.equipmentNo + '> ' +
                            '<span> <i class="fas fa-thumbs-up fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            'Select' + '</a>' + '</label>';
                    },
                },
                {
                    data: "equipmentNo",
                    name: "Equipment No.",
                },
                {
                    data: "equipmentDescription",
                    name: "Equipment Description"
                },
                {
                    data: "equipmentParentNo",
                    name: "Parent Equipment No.",
                },
                {
                    data: "equipmentParentDescription",
                    name: "Parent Equipment Description"
                },
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center',
                },
                {
                    targets: [0, 1, 3],
                    className: 'dt-body-center',
                },
                {
                    targets: 4,
                    render: function (data, type, row) {
                        return data.substr(0, 15) + '...';
                    }
                },
                /* { orderable: false, targets: [0, 1, 2, 3, 4] }*/
                //{ orderable: false, targets: 1 },
                //{ orderable: false, targets: 2 },
                //{ orderable: false, targets: 3 },
            ],
        });
    }
}
function SaveEquipmentNo() {
    try {
        let _requisitionNo = (document.getElementById("txtRequisitionNo").value);
        let _equipmentNo = (document.getElementById("txtEquipmentNo").value);
        let _parentEquipmentNo = (document.getElementById("txtEquipmentParentNo").value);
        let _isEquipmentNoRequired = Boolean(document.getElementById("chkEquipmentNoRequired").checked);
        container = $('.Manage-equip');
        HideLoadingPanel(container);
        if (_equipmentNo == '') {
            const CONST_REQUESTNO = "Please select Equipment number for this requisition!";
            ShowToastMessage(toastTypes.error, CONST_REQUESTNO, "Requisition No.");
            LoadEquipmentNoDataTable();
            return;
        }
        $.ajax({
            url: "/AdminFunctions/Admin/SaveEquipmentNo",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: {
                RequisitionNo: _requisitionNo,
                EquipmentNo: _equipmentNo,
                ParentEquipmentNo: _parentEquipmentNo,
                IsEquipmentNoRequired: _isEquipmentNoRequired,
            },
            success: function (response, status) {
                if (status == "success") {
                    ShowToastMessage(toastTypes.success, "Equipment number updated for this requisition", "Equipment Number Saved");
                    //HideLoadingPanel(gContainer);
                    setTimeout(() => { console.log('loading.!'); }, 20000);
                    container = $('.formWrapper');
                    ShowLoadingPanel(container, 1, 'Redirecting to Equipment No. assignment page..');
                    //location.href = "/AdminFunctions/Admin/ManageEquipmentNo/";           
                    // Open the Requisition Details View
                    location.href = "/AdminFunctions/Admin/ManageEquipmentNo/?Status=".concat(status.toString());
                }
                else {
                    throw new Error("Something went wrong while fethcing data from the database !");
                }
            },
            error: function (err) {
                throw err;
            }
        });
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>");
    }
}
$("#chkEquipmentNoRequired").click(function () {
    if ($(this).is(":checked")) {
        $("#btnChoose").removeAttr("disabled");
        $('#btnChoose').removeAttr("hidden");
        $("#btnSave").removeAttr('disabled');
    }
    else {
        $("#btnChoose").attr('disabled', 'disabled');
        $('#btnChoose').attr("hidden", "hidden");
        $("#btnSave").attr('disabled', 'disabled');
        const CONST_REQUESTNO_NOT = "Equipment number is NOT required for this Requisition !";
        ShowToastMessage(toastTypes.info, CONST_REQUESTNO_NOT, "Requisition No.");
    }
});
function LoadEquipmentAssignment(ReqestNo) {
    $('#btnSearch').attr("disabled", "disabled");
    //// Show/hide the spinner icon
    //$('span[class~="spinicon"]').removeAttr("hidden");
    //$('span[class~="normalicon"]').attr("hidden", "hidden");
    container = $('.gridWrapper');
    ShowLoadingPanel(container, 2, 'Redirecting to Equipment No. assignment page..');
    //let Url = '/AdminFunctions/Admin/ManageEquipmentNoEdit/' + ReqestNo;
    //location.href = Url;
    let actionType = 0;
    // Open the Requisition Details View
    location.href = "/AdminFunctions/Admin/ManageEquipmentNoEdit/?id=".concat(ReqestNo.toString())
        .concat("&actionType=").concat(actionType.toString())
        .concat("&user_empno=").concat(gUserAccess.empNo.toString())
        .concat("&user_empname=").concat(gUserAccess.empName.trim())
        .concat("&callerForm=").concat(PageControllerMapping.ManageEquipmentNo.toString());
}
//function getPageReload() {
//    const CONST_EQUIP_SAVED = "Equipment number is assigned for this Requisition !";
//    ShowToastMessage(toastTypes.success, CONST_EQUIP_SAVED, "Equipment Number");
//    container = $('.formWrapper');
//    ShowLoadingPanel(container, 1, 'Updating the Equipment No. to the requisition.');
//    setTimeout(() => { console.log('loading.!'); }, 6000);
//    let id: string = "0";
//    let actionType = 0;
//    location.href = "/AdminFunctions/Admin/ManageEquipmentNo/?id=".concat(id)
//        .concat("&actionType=").concat(actionType.toString())
//        .concat("&user_empno=").concat(gUserAccess.empNo.toString())
//        .concat("&user_empname=").concat(gUserAccess.empName.trim())
//        .concat("&callerForm=").concat(PageControllerMapping.ManageEquipmentNo.toString());
//}
//# sourceMappingURL=ManageEquipmentNo.js.map