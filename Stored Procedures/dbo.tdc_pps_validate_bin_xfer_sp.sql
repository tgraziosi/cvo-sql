SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_bin_xfer_sp]

@bPacking	INT,
@bSerialized	INT,
@XferNo	INT,
@PartNo		VARCHAR(30),
@Location	VARCHAR(15),
@Lot		VARCHAR(30),
@Bin		VARCHAR(12),
@ErrMsg		VARCHAR(255) OUTPUT
AS

DECLARE @Cnt    INT 
DECLARE @VSN	CHAR(1)

--FIELD INDEXES TO BE RETURNED TO VB
DECLARE @ID_QUANTITY		INT
DECLARE @ID_SCAN_SERIAL	 	INT

SELECT @VSN = 'N'

--Set the values of the field indexes
SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'QUANTITY'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SCAN_SERIAL'


	IF (LTRIM(RTRIM(@Bin)) = '') 
	BEGIN
		SELECT @ErrMsg = 'You must enter a bin'
		RETURN -1
	END

	--If packing
	IF (@bPacking = 1 )
	BEGIN
            --check if bin exists in selected lot, and contains current part
		--SCR #37905
--              SELECT @Cnt = COUNT(DISTINCT tbi.bin_no)
--                 FROM xfer_list ol (NOLOCK) , lot_bin_stock tbi (NOLOCK)  
--                WHERE ol.xfer_no =  @XferNo
--                  	AND ol.part_no = tbi.part_no  
--                  	AND tbi.part_no = @PartNo
--                  	AND tbi.bin_no = @Bin
--                  	AND tbi.lot_ser = @Lot
		SELECT @Cnt = COUNT(DISTINCT bin_no)
               	  FROM tdc_dist_item_pick (NOLOCK)  
              	 WHERE [function] = 'T'
            	   AND order_no = @XferNo
         	   AND part_no = @PartNo
            	   AND bin_no = @Bin
               	   AND lot_ser = @Lot
		   AND quantity > 0
	END --If packing
	ELSE --Not Packing
	BEGIN
		SELECT @Cnt = COUNT(DISTINCT tbi.bin_no)
                	FROM xfer_list ol (NOLOCK) , lot_bin_stock tbi (NOLOCK)  
                	WHERE ol.xfer_no =  @XferNo
                     	AND ol.part_no = tbi.part_no  
                     	AND tbi.part_no = @PartNo
                     	AND tbi.bin_no = @Bin
                     	AND tbi.lot_ser = @Lot
	END

	--if no records, invalid bin
	IF (@Cnt = 0)
	BEGIN
		SELECT @ErrMsg = 'Invalid bin.'
		RETURN -1
	END
	
	--If serialized
	IF (@bSerialized = 1) 
	BEGIN

		SELECT @VSN = vendor_sn FROM tdc_inv_list (NOLOCK)
		     	      WHERE part_no = @PartNo
		     	      AND location = @Location

		--If part serial tracked, set the flag
		IF (EXISTS(SELECT * FROM tdc_inv_master (NOLOCK)
			  WHERE part_no = @PartNo)
			  AND (@vsn <> 'N'))
		BEGIN
			RETURN @ID_SCAN_SERIAL
		END
	END
	--SCR #37905
	RETURN @ID_QUANTITY
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_bin_xfer_sp] TO [public]
GO
