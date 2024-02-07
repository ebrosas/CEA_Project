using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class ApproversDetails
    {
        [Key]
        public string? RequisitionNo { get; set; }
        public int ApproverEmpNo { get; set; }                

        public string? ApproverName { get; set; }
        public string? ApproverEmail { get; set; }

        public string? ApprovalStatus { get; set; }        

        public string? CEADescription { get; set; }
    }
}
