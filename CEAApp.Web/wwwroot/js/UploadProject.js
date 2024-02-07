//export { }
var container;
var file;
$(() => {
    // Set the current container
    gContainer = $('.gridWrapper');
    $("#exportTable")
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
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.ProjectUpload);
        $("#hidUserEmpNo").val(model.empNo);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.ProjectUpload);
    }
    // #endregion
});
function encodeImageFileAsURL(element) {
    try {
        file = element.files[0];
    }
    catch (err) {
        ShowErrorMessage("The following error has occured while executing encodeImageFileAsURL() method.\n\n" + err);
    }
}
function PopulateExportDataTable(data) {
    gContainer = $('.gridWrapper');
    var dataset = data;
    if (data == null || data === undefined) {
        // Get DataTable API instance
        var table = $("#exportTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
        return;
    }
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#exportTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        $("#exportTable")
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
            //sScrollX: "100%",
            //sScrollXInner: "110%",      // This property can be used to force a DataTable to use more width than it might otherwise do when x-scrolling is enabled.
            language: {
                emptyTable: "No records found in the database."
            },
            //width: "100%",
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[1, 'desc']],
            //drawCallback: function () {
            //    $('.lnkProjectNo').on('click', getProjectDetails);
            //},
            columns: [
                {
                    data: "fiscalYear",
                    name: "Fiscal Year",
                },
                {
                    data: "costCenter",
                    name: "Cost Center",
                },
                {
                    data: "projectNo",
                    name: "Project No",
                },
                {
                    data: "expectedProjectDate",
                    render: function (data) {
                        return '<label">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: "expenditureType",
                    name: "Expense Type",
                },
                {
                    data: "categoryCode1",
                    name: "Expense Category",
                },
                {
                    data: "description",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "detailDescription",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "projectAmount",
                    name: "Amount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "accountCode",
                    name: "Account Cost Center",
                },
                {
                    data: "objectCode",
                    name: "Object",
                },
                {
                    data: "subjectCode",
                    name: "Subject",
                },
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                {
                    targets: [0, 1, 2, 3, 4, 5, 9],
                    className: 'dt-body-center',
                },
                {
                    targets: [7],
                    className: "dt-body-left",
                },
                {
                    targets: [5, 10],
                    className: "dt-body-left",
                },
                {
                    targets: [8],
                    className: "dt-body-right",
                },
            ]
        });
    }
}
var _validFileExtensions = [".xls", ".xlsx"];
function ValidateFileInput(oInput) {
    if (oInput.type == "file") {
        var sFileName = oInput.value;
        if (sFileName.length > 0) {
            var blnValid = false;
            for (var j = 0; j < _validFileExtensions.length; j++) {
                var sCurExtension = _validFileExtensions[j];
                if (sFileName.substr(sFileName.length - sCurExtension.length, sCurExtension.length).toLowerCase() == sCurExtension.toLowerCase()) {
                    blnValid = true;
                    break;
                }
            }
            if (!blnValid) {
                const CONST_FILE_INVALID = "Sorry, " + sFileName + " is invalid, The allowed extensions are: " + _validFileExtensions.join(", ");
                ShowToastMessage(toastTypes.error, CONST_FILE_INVALID, "Invalid File Type");
                oInput.value = "";
                return false;
            }
        }
    }
    return true;
}
//# sourceMappingURL=UploadProject.js.map