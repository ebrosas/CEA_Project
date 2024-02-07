namespace CEAApp.Web.Models
{
    public class CEAAdminInfo : EmployeeInfo
    {
        #region Properties
        public int RequisitionNo { get; set; }
        public string? CEADescription { get; set; }
        #endregion
    }
}
