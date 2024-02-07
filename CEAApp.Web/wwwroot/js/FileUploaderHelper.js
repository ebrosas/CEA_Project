
// Hide all error alerts
$('.errorPanel').attr("hidden", "hidden");
$("#btnSaveProject").attr("disabled", "disabled");
$("#btnSaveProject").removeClass("btn-success").removeClass("text-white").addClass("btn-outline-success");

const buttonView = document.getElementById('btnViewProject');

    buttonView === null || buttonView === void 0 ? void 0 : buttonView.addEventListener('click', function handleClick(event) {
        let hasError = false;
        // Check uploaded the file
        if ($("#uploadPhoto")[0].files[0] == undefined) {
            displayError($('#UploadError'), "<b>" + $(".fieldLabel label[data-field='uploadPhoto']").text() + "</b> is required and cannot be left blank.", $('input[name="uploadPhoto"'));
            hasError = true;
        }
        else {
            if ($('#UploadError').attr("hidden") == undefined)
                $('#UploadError').attr("hidden", "hidden");
        }

        if (!hasError) {
            container = $('.gridWrapper');
            ShowLoadingPanel(container, 2, 'Loading data...');

            LoadUploadDataTable(file);            
            $("#btnViewProject").removeClass("btn-primary").addClass("btn-outline-primary").removeClass("text-white");
            $("#btnViewProject").attr("disabled", "disabled");

            $("#btnSaveProject").removeClass("btn-outline-success").addClass("btn-success").addClass("text-white");
            $("#btnSaveProject").removeAttr("disabled");  
            /*clear the datatable */
            var table = $("#exportTable").dataTable().api();
            table.clear().draw();
        }
    });

function LoadUploadDataTable() {
    try {
            var formData = new FormData();
            formData.append("file", $("#uploadPhoto")[0].files[0]);

            $.ajax({
                url: "/AdminFunctions/Admin/FileUpload",
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                success: function (response, status) {
                    if (status == "success") {

                        PopulateExportDataTable(response.data);
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

const buttonSave = document.getElementById('btnSaveProject');

    buttonSave === null || buttonSave === void 0 ? void 0 : buttonSave.addEventListener('click', function handleClick(event) {
        let hasError = false;
        // Check uploaded the file
        if ($("#uploadPhoto")[0].files[0] == undefined) {
            displayError($('#UploadError'), "<b>" + $(".fieldLabel label[data-field='uploadPhoto']").text() + "</b> is required and cannot be left blank.", $('input[name="uploadPhoto"'));
            hasError = true;
        }
        else {
            if ($('#UploadError').attr("hidden") == undefined)
                $('#UploadError').attr("hidden", "hidden");
        }

        if (!hasError) {
            $("#btnSaveProject").attr("disabled", "disabled");
            $("#btnViewProject").removeAttr("disabled");

            $("#btnViewProject").removeClass("btn-outline-success").addClass("btn-primary").addClass("text-white"); 
            $("#btnSaveProject").removeClass("btn-primary").addClass("btn-outline-success").removeClass("text-white");

            container = $('.gridWrapper');
            ShowLoadingPanel(container, 2, 'Loading data...');

            SaveUploadDataTable(file);
            // Reset dataTable
            var table = $("#exportTable").dataTable().api();
            table.clear().draw();  
            $("#uploadPhoto").val('');
        }
    });


function SaveUploadDataTable() {
    try {
        let userName = GetStringValue($("#hidUserName").val());
        var formData = new FormData();
        formData.append("file", $("#uploadPhoto")[0].files[0]);
        formData.append("UserName", userName);

            $.ajax({
                url: "/AdminFunctions/Admin/SaveExcel",
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                success: function (response, status) {

            if (status == "success") {
                //ShowErrorMessage("Data Saved Successfully");
                ShowToastMessage(toastTypes.success, "Excel data saved successfully into the database!", "Data saved successful");
                HideLoadingPanel(container);
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

function displayError(obj, errText, focusObj) {
    var alert = $(obj).find(".alert");

    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);

    if (obj != undefined)
        $(obj).removeAttr("hidden");

    $(alert).show();

    if (focusObj != undefined)
        $(focusObj).focus();
}

function ResetButtonClick() {
    // Reset dataTable
    var table = $("#exportTable").dataTable().api();
    table.clear().draw();

    // Move to the top of the page
    window.scrollTo(0, 0);

    $('#UploadError').attr("hidden", "hidden");

    $("#btnSaveProject").attr("disabled", "disabled");
    $("#btnViewProject").removeAttr("disabled");
    $("#btnViewProject").removeClass("btn-outline-success").addClass("btn-primary").addClass("text-white");
    $("#btnSaveProject").removeClass("btn-primary").addClass("btn-outline-success").removeClass("text-white");
}