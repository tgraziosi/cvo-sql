SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_asn_weight_sp]
	@intASN_No	INTEGER ,
	@intTotal 	INTEGER OUTPUT
AS

DECLARE @intChildSerial	AS INTEGER,
	@intWeight	AS INTEGER

SELECT @intTotal = 0

DECLARE ASN_Cursor CURSOR FOR 
	SELECT DISTINCT child_serial_no FROM tdc_dist_group WHERE parent_serial_no = @intASN_No
OPEN ASN_Cursor
FETCH NEXT FROM ASN_Cursor INTO @intChildSerial
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @intWeight = isnull(weight,0) FROM tdc_carton_tx WHERE carton_no = @intChildSerial
		SELECT @intTotal = @intTotal + @intWeight
		FETCH NEXT FROM ASN_Cursor INTO @intChildSerial
	END

CLOSE ASN_Cursor
DEALLOCATE ASN_Cursor

GO
GRANT EXECUTE ON  [dbo].[tdc_asn_weight_sp] TO [public]
GO
