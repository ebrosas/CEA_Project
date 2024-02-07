namespace CEAApp.Web.Models
{
    public class Equipment
    {
        #region Properties
        public string equipmentNo { get; set; } = null!;
        public string equipmentDesc { get; set; } = null!;
        public string parentEquipmentNo { get; set; } = null!;
        public string parentEquipmentDesc { get; set; } = null!;
        #endregion
    }
}
