using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class EmployeeDetail
    {
        #region Properties
        [Key]
        [Display(Name = "Emp. #")]
        public int empNo { get; set; }

        [Display(Name = "Emp. Name")]
        public string empName { get; set; } = null!;

        [Display(Name = "Cost Center")]
        public string costCenter { get; set; } = null!;

        [Display(Name = "Cost Center Name")]
        public string costCenterName { get; set; } = null!;

        [Display(Name = "Pay Grade")]
        public int? payGrade { get; set; }

        public string? payStatus { get; set; } = null!;

        [Display(Name = "Date of Join")]
        public DateTime? dateJoined { get; set; }


        public int? supervisorEmpNo { get; set; } = null!;
        public string supervisorEmpName { get; set; } = null!;

        [Display(Name = "Email")]
        public string email { get; set; } = null!;
        #endregion

        #region Extended Properties
        public string userID { get; set; } = null!;
        public int superintendentEmpNo { get; set; }
        public string superintendentEmpName { get; set; } = null!;
        public int? managerEmpNo { get; set; }
        public string managerEmpName { get; set; } = null!;
        public string position { get; set; } = null!;
        public string phoneExtension { get; set; } = null!;
        public string workingCostCenter { get; set; } = null!;
        public string workingCostCenterName { get; set; } = null!;

        public string? employeeFullName
        {
            get
            {
                if (this.empNo > 0)
                    return $"{this.empNo} - {this.empName}";
                else
                    return string.Empty;
            }
        }

        [Display(Name = "Supervisor")]
        public string? supervisorFullName
        {
            get
            {
                if (this.supervisorEmpNo > 0)
                    return $"({this.supervisorEmpNo}) {this.supervisorEmpName}";
                else
                    return string.Empty;
            }
        }
        #endregion
    }
}
