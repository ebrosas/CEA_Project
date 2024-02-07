using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class Reassignment
    {

        public string CostCenter { get; set; } = null!;

        public string ExpenditureType { get; set; } = null!;

        public int CurrentEmpNo { get; set; }

        public string RequisitionNo { get; set; } = null!;

        public int? FiscalYear { get; set; }

        public int NewApproverEmpNo { get; set; }

        public string Remarks { get; set; } = null!;

    }
}
