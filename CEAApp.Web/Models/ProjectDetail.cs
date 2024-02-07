using System.Reflection.Metadata.Ecma335;

namespace CEAApp.Web.Models
{
    public class ProjectDetail
    {
        #region Properties
        public decimal projectID { get; set; }
        public string? projectNo { get; set; }
        public DateTime? projectDate { get; set; }
        public int companyCode { get; set; }
        public string? costCenter { get; set; }
        public string? expenditureType { get; set; }
        public string? description { get; set; }
        public string? detailDescription { get; set; }
        public string? accountCode { get; set; }
        public string? projectType { get; set; }
        public int fiscalYear { get; set; }
        public decimal projectAmount { get; set; }
        public decimal projectStatusID { get; set; }
        public int? projectStatus { get; set; }
        public string? projectStatusDesc { get; set; }
        public string? createBy { get; set; }
        public DateTime? createDate { get; set; }
        #endregion
    }
}
