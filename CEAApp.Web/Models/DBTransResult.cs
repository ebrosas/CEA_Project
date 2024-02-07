namespace CEAApp.Web.Models
{
    [Serializable]
    public class DBTransResult
    {
        #region Properties
        public int RowsAffected { get; set; }
        public int NewIdentityID { get; set; }
        public bool HasError { get; set; }
        public string? ErrorCode { get; set; }
        public string? ErrorDesc { get; set; }
        public string CEANo { get; set; } = null!;
        public int ErrorID { get; set; }
        public int NextSequenceNo { get; set; }
        #endregion
    }
}
