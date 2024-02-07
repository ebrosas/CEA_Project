namespace CEAApp.Web.Models
{
    public class EmployeeInfo
    {
        #region Properties
        public int EmpNo { get; set; }
        public string? EmpName { get; set; }
        public string? Position { get; set; }
        public string? CostCenter { get; set; }
        public string? CostCenterName { get; set; }
        public string? CustomCostCenter { get; set; }
        public int PayGrade { get; set; }
        public int? SupervisorNo { get; set; }
        public string? SupervisorName { get; set; }
        public int? ManagerNo { get; set; }
        public string? ManagerName { get; set; }
        public string? CompanyName { get; set; }
        public int? UserEmpNo { get; set; }
        public string? UserID { get; set; }
        public string? Email { get; set; }
        public string? PhoneExt { get; set; }

        public string? CostCenterFullName
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(CostCenter))
                    return string.Format("{0} - {1}", CostCenter, CostCenterName);
                else
                    return CostCenterName;
            }
        }

        public string? EmployeeFullName
        {
            get
            {
                if (EmpNo > 0)
                    return string.Format("{0} - {1}", EmpNo, EmpName);
                else
                    return EmpName;
            }
        }

        public string? SupervisorFullName
        {
            get
            {
                if (SupervisorNo > 0)
                    return string.Format("{0} - {1}", SupervisorNo, SupervisorName);
                else
                    return SupervisorName;
            }
        }

        public string? ManagerFullName
        {
            get
            {
                if (ManagerNo > 0)
                    return string.Format("{0} - {1}", ManagerNo, ManagerName);
                else
                    return ManagerName;
            }
        }
        #endregion

        #region Public Methods
        public string? GetEmployeeFullName()
        {
            if (EmpNo > 0)
                return string.Format("{0} - {1}", EmpNo, EmpName);
            else
                return EmpName;
        }

        public string? GetSupervisorFullName()
        {
            if (SupervisorNo > 0)
                return string.Format("{0} - {1}", SupervisorNo, SupervisorName);
            else
                return SupervisorName;
        }

        public string? GetManagerFullName()
        {
            if (ManagerNo > 0)
                return string.Format("{0} - {1}", ManagerNo, ManagerName);
            else
                return ManagerName;
        }
        #endregion
    }
}
