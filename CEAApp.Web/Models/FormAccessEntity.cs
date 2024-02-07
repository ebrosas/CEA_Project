namespace CEAApp.Web.Models
{
    public class FormAccessEntity : EmployeeInfo
    {
        #region Properties
        public string FormCode { get; set; } = null!;
        public string FormName { get; set; } = null!;
        public string FormFilename { get; set; } = null!;
        public bool FormPublic { get; set; } 
        public string UserFrmCRUDP { get; set; } = null!;
        public string ApplicationName { get; set; } = null!;
        #endregion

        #region Parameters
        public byte mode { get; set; }
        public int userFrmFormAppID { get; set; }
        public string userFrmFormCode { get; set; } = null!;
        public string userFrmCostCenter { get; set; } = null!;
        public int userFrmEmpNo { get; set; }
        public string userFrmEmpName { get; set; } = null!;
        public string sort { get; set; } = null!;
        #endregion
    }
}
