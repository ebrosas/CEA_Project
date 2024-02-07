
$(function () {
    resetForm();
});

function resetForm() {
    $("#btnHiddenReset").click();

    // Reset DataTable
    populateDataTable();

    // Move to the top of the page
    window.scrollTo(0, 0);
}

function populateDataTable(data) {
    try {
        if (data == "undefined" || data == null || data == "") {
            // Get DataTable API instance
            var table = $("#projectTable").dataTable().api();
            table.clear().draw();
            HideLoadingPanel(gContainer);
            return;
        }
    }
    catch (err) {
        //ShowErrorMessage("The following error has occured while populating the data into the grid.\n\n" + err);
    }
}