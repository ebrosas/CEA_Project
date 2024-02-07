using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class FileAttachment
    {
        #region Properties
        [Key]
        public decimal RequisitionAttachmentID { get; set; }
        public string RequisitionNo { get; set; } = null!;
        public decimal RequisitionID { get; set; }
        public int FiscalYear { get; set; }
        public string CostCenter { get; set; } = null!;
        public string AttachmentFileName { get; set; } = null!;

        [Display(Name = "Filename")]
        public string AttachmentDisplayName { get; set; } = null!;

        [Display(Name = "File Size")]
        [DisplayFormat(DataFormatString = "{0:0,000}", ApplyFormatInEditMode = true)]
        public decimal? AttachmentSize { get; set; }

        public int? CreatedByEmpNo { get; set; }

        [Display(Name = "Created by")]
        public string CreatedBy { get; set; }=null!;

        [Display(Name = "Created Date")]
        [DisplayFormat(DataFormatString = "{0:dd-MMM-yyyy}", ApplyFormatInEditMode = true)]
        public DateTime? CreatedDate { get; set; }

        public bool IsDummy { get; set; }
        public string Base64File { get; set; } = null!;
        public string Base64FileExt { get; set; } = null!;
        #endregion
    }
}
