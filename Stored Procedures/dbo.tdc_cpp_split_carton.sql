SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_cpp_split_carton] (
	@source_serial_no int,
	@part_no	  varchar(30),
	@dest_quantity	  decimal(20,8),
	@dest_serial_no	  int
	) AS

DECLARE	@source_quantity	int,
	@child_serial_no	int,
	@group_status		char,
	@return_status		int,
	@function		char

SELECT @return_status = 1

SELECT	@source_quantity = g.quantity,
	@child_serial_no = g.child_serial_no,
	@group_status = g.status,
	@function = g.[function]
	FROM	tdc_dist_group g, tdc_dist_item_pick ip
	WHERE	g.parent_serial_no = @source_serial_no
	  AND	g.child_serial_no = ip.child_serial_no
	  AND	ip.part_no = @part_no
IF (@source_quantity < @dest_quantity)
	SELECT @return_status = -9600
ELSE BEGIN
BEGIN TRANSACTION
	INSERT INTO tdc_dist_group (method,type,parent_serial_no,child_serial_no,quantity,status,[function] )
		VALUES('PP', 'PP', @dest_serial_no, @child_serial_no, @dest_quantity, @group_status, @function)
	IF (@source_quantity = @dest_quantity)
		DELETE	tdc_dist_group
			WHERE	parent_serial_no = @source_serial_no
			  AND	child_serial_no = @child_serial_no
	ELSE
		UPDATE	tdc_dist_group
			SET	quantity = quantity - @dest_quantity
			WHERE	parent_serial_no = @source_serial_no
			  AND	child_serial_no = @child_serial_no
COMMIT TRANSACTION
END

RETURN @return_status


GO
GRANT EXECUTE ON  [dbo].[tdc_cpp_split_carton] TO [public]
GO
