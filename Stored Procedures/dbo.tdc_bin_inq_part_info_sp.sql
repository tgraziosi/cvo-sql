SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/03/2012 - Display primary / secondary bins for the part even with no stock  
                                           
CREATE PROCEDURE [dbo].[tdc_bin_inq_part_info_sp]  
  @bin_type varchar(30),  
  @bin_no   varchar(12),  
  @location varchar(10)  
  
AS  
  
TRUNCATE TABLE #tdc_bin_inq_part_info  
  
IF @bin_type = 'PASSBIN' OR @bin_type = 'CDBIN'  
BEGIN   
 INSERT INTO #tdc_bin_inq_part_info(part_no, lot_ser, date_expires, qty, status, res_type, part_group, void)  
 SELECT a.part_no, ISNULL(lot_ser, ''), NULL, SUM(qty),   
        CASE status WHEN 'K' THEN 'Auto-Kit'  
      WHEN 'H' THEN 'Make/Routed'  
      WHEN 'M' THEN 'Make'  
      WHEN 'P' THEN 'Purchase'  
      WHEN 'Q' THEN 'Purchase/Outsource'  
      WHEN 'R' THEN 'Resource'  
        END,  
        type_code, category,  
        CASE void WHEN 'N' THEN 0 ELSE -1 END  
     FROM tdc_soft_alloc_tbl a (NOLOCK),  
        inv_master   b (NOLOCK)  
   WHERE dest_bin  = @bin_no  
    AND location  = @location  
    AND a.part_no = b.part_no  
  GROUP BY a.part_no, lot_ser, b.status, b.type_code, b.category, b.void  
END  
  
IF @bin_type = 'STLBIN'  
BEGIN   
 INSERT INTO #tdc_bin_inq_part_info(part_no, lot_ser, date_expires, qty, status, res_type, part_group, void)  
 SELECT DISTINCT a.part_no, ISNULL(lot_ser, ''), '', SUM(pack_qty),  
        CASE b.status WHEN 'K' THEN 'Auto-Kit'  
        WHEN 'H' THEN 'Make/Routed'  
        WHEN 'M' THEN 'Make'  
        WHEN 'P' THEN 'Purchase'  
        WHEN 'Q' THEN 'Purchase/Outsource'  
        WHEN 'R' THEN 'Resource'  
        END,  
        type_code, category,  
        CASE b.void WHEN 'N' THEN 0 ELSE -1 END  
   FROM tdc_carton_detail_tx a (NOLOCK),  
        inv_master     b (NOLOCK)   
  WHERE carton_no IN (SELECT DISTINCT carton_no FROM tdc_carton_tx WHERE stlbin_no = @bin_no)  
    AND a.part_no = b.part_no  
  GROUP BY a.part_no, lot_ser, b.status, b.type_code, b.category, b.void  
END  
  
IF @bin_type = 'TOTE'  
BEGIN   
 INSERT INTO #tdc_bin_inq_part_info(part_no, lot_ser, date_expires, qty, status, res_type, part_group, void)  
 SELECT a.part_no, lot_ser, '', SUM(quantity),  
        CASE status WHEN 'K' THEN 'Auto-Kit'  
      WHEN 'H' THEN 'Make/Routed'  
      WHEN 'M' THEN 'Make'  
      WHEN 'P' THEN 'Purchase'  
      WHEN 'Q' THEN 'Purchase/Outsource'  
      WHEN 'R' THEN 'Resource'  
        END,  
        type_code, category,  
        CASE void WHEN 'N' THEN 0 ELSE -1 END  
   FROM tdc_tote_bin_tbl a (NOLOCK),  
        inv_master       b (NOLOCK)   
  WHERE bin_no    = @bin_no  
    AND location  = @location  
    AND a.part_no = b.part_no  
  GROUP BY a.part_no, lot_ser, b.status, b.type_code, b.category, b.void  
END  
ELSE -- For ... BINs  
BEGIN   
 INSERT INTO #tdc_bin_inq_part_info(part_no, lot_ser, date_expires, qty, status, res_type, part_group, void)  
 SELECT a.part_no, lot_ser, date_expires, SUM(qty),  
        CASE status WHEN 'K' THEN 'Auto-Kit'  
      WHEN 'H' THEN 'Make/Routed'  
      WHEN 'M' THEN 'Make'  
      WHEN 'P' THEN 'Purchase'  
      WHEN 'Q' THEN 'Purchase/Outsource'  
      WHEN 'R' THEN 'Resource'  
        END,  
        type_code, category,  
        CASE void WHEN 'N' THEN 0 ELSE -1 END  
   FROM lot_bin_stock a (NOLOCK),  
        inv_master    b (NOLOCK)  
  WHERE bin_no    = @bin_no  
    AND location  = @location  
    AND a.part_no = b.part_no  
  GROUP BY a.part_no, lot_ser, date_expires, b.status, b.type_code, b.category, b.void  
UNION -- v1.0 Start
 SELECT a.part_no, '', CONVERT(varchar(10),GETDATE(),101), 0 qty,  
        CASE status WHEN 'K' THEN 'Auto-Kit'  
      WHEN 'H' THEN 'Make/Routed'  
      WHEN 'M' THEN 'Make'  
      WHEN 'P' THEN 'Purchase'  
      WHEN 'Q' THEN 'Purchase/Outsource'  
      WHEN 'R' THEN 'Resource'  
        END,  
        type_code, category,  
        CASE void WHEN 'N' THEN 0 ELSE -1 END  
   FROM tdc_bin_part_qty a (NOLOCK)
   JOIN inv_master    b (NOLOCK)
	ON a.part_no = b.part_no
   LEFT JOIN lot_bin_stock c (NOLOCK)  
   ON a.location = c.location
   AND a.part_no = c.part_no
   AND a.bin_no = c.bin_no
   WHERE a.bin_no    = @bin_no  
    AND a.location  = @location 
    AND c.location IS NULL
	AND c.part_no IS NULL
	AND c.bin_no IS NULL
-- v1.0 End
END  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_bin_inq_part_info_sp] TO [public]
GO
