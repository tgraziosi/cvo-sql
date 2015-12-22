SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_upc_upload_sp]
  @loc VARCHAR(10) = NULL
, @bin VARCHAR(20) = NULL
, @direction INT = 1
, @reason VARCHAR(10) = 'ADHOC'
, @debug INT = 0

AS
BEGIN

/*

EXEC CVO_UPC_UPLOAD_SP '001','RR REFURB', -1, 'ADHOC', 1
TRUNCATE TABLE CVO_UPC_UPLOAD
SELECT * fROM CVO_UPC_UPLOAD

SELECT * fROM ISSUES (NOLOCK) WHERE ISSUE_NO >=4641583

*/
	DECLARE	@row_id			int,
			@last_row_id	int,
			@location		varchar(10),
			@part_no		varchar(30),
			@bin_no			varchar(20),
			@qty			decimal(20,8),
			@reason_code	varchar(10),
			@code			VARCHAR(10),
			@bin_qty		DECIMAL(20,8)

	SELECT @reason_code = CASE WHEN @reason = 'WRITEOFF' THEN 'WRITE-OFF' ELSE 'ADJ-ADHOC' END
	SELECT @CODE = CASE WHEN @REASON = 'WRITEOFF' THEN @REASON ELSE 'ADHOC' END

	-- set up temp tables

	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj  
	END

	CREATE TABLE #adm_inv_adj (
		adj_no			int	null,
		loc				varchar(10) not null,
		part_no			varchar(30)	not null,
		bin_no			varchar(12) null,
		lot_ser			varchar(25) null,
		date_exp		datetime null,
		qty				decimal(20,8) not null,
		direction		int	not null,
		who_entered		varchar(50)	not null,
		reason_code		varchar(10) null,
		code			varchar(8) not null,
		cost_flag		char(1)	null,
		avg_cost		decimal(20,8) null,
		direct_dolrs	decimal(20,8) null,
		ovhd_dolrs		decimal(20,8) null,
		util_dolrs		decimal(20,8) null,
		err_msg			varchar(255) null,
		row_id			int identity not null)

	
	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj_log')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj_log
	END

	CREATE TABLE #adm_inv_adj_log (
		adj_no			int	null,
		loc				varchar(10) not null,
		part_no			varchar(30)	not null,
		bin_no			varchar(12) null,
		lot_ser			varchar(25) null,
		date_exp		datetime null,
		qty				decimal(20,8) not null,
		direction		int	not null,
		who_entered		varchar(50)	not null,
		reason_code		varchar(10) null,
		code			varchar(8) not null,
		cost_flag		char(1)	null,
		avg_cost		decimal(20,8) null,
		direct_dolrs	decimal(20,8) null,
		ovhd_dolrs		decimal(20,8) null,
		util_dolrs		decimal(20,8) null,
		err_msg			varchar(255) null,
		row_id			int not null)


	IF (OBJECT_ID('tempdb..#temp_who') IS NULL)   
	BEGIN  
		CREATE TABLE #temp_who (  
			who        varchar(50),   
			login_id   varchar(50))  
	END  

	IF (SELECT OBJECT_ID('tempdb..#cvo_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #cvo_inv_adj  
	END

	CREATE TABLE #cvo_inv_adj (
		row_id			int IDENTITY(1,1),
		location		varchar(10),
		upc_code		varchar(30),
		part_no			varchar(30),
		bin_no			varchar(20),
		qty				decimal(20,8))

	INSERT	#cvo_inv_adj (location, upc_code, part_no, bin_no, qty)
	-- SELECT	location, upc_code, '', bin_no, reason_code, qty
	SELECT @LOC, UPC_CODE, '', @BIN, SUM(ISNULL(QTY,1)) QTY
	FROM	dbo.cvo_upc_upload
	GROUP BY UPC_CODE
	--SELECT * FROM dbo.cvo_upc_upload
	-- validate data

	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT 'Nothing to process!'
		RETURN
	END
	
	IF NOT EXISTS ( SELECT 1 FROM TDC_BIN_MASTER WHERE LOCATION = @LOC AND bin_no = @BIN )
	BEGIN 
		SELECT 'Invalid Location or Bin'
		RETURN
    END

	IF @direction NOT IN (1,-1) 
	BEGIN
		SELECT 'Invalid Direction.  Must be 1 or -1'
		RETURN
    END

	UPDATE A 
	SET PART_NO = A.UPC_CODE
	FROM #CVO_INV_ADJ A
	WHERE EXISTS (SELECT 1 FROM INV_MASTER (NOLOCK) WHERE PART_NO = A.UPC_CODE)

	UPDATE	a
	SET		part_no = b.part_no
	FROM	#cvo_inv_adj a
	JOIN	uom_id_code b
	ON		a.upc_code = b.upc
	WHERE ISNULL(A.PART_NO,'') = ''

	IF @debug = 1 SELECT * FROM #cvo_inv_adj ORDER BY PART_NO

	IF EXISTS (SELECT 1 FROM #cvo_inv_adj WHERE part_no = '')
	BEGIN
		SELECT 'List contains invalid part numbers or upc codes!'
		SELECT * FROM #cvo_inv_adj WHERE part_no = ''
		RETURN
	END

	-- Start processing transactions

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@location = location,
			@part_no = part_no,
			@bin_no = bin_no,
			@qty = qty
	FROM	#cvo_inv_adj
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		TRUNCATE TABLE #adm_inv_adj

		IF @direction = -1 
		BEGIN
			SELECT @bin_qty = 0
			SELECT @bin_qty = SUM(ISNULL(qty,0)) 
			FROM lot_bin_stock 
			WHERE location = @loc AND bin_no = @bin AND part_no = @part_no
			
			IF @qty > ISNULL(@bin_qty ,@qty)
			
				INSERT INTO #adm_inv_adj_log
				        ( adj_no ,
				          loc ,
				          part_no ,
				          bin_no ,
				          lot_ser ,
				          date_exp ,
				          qty ,
				          direction ,
				          who_entered ,
				          reason_code ,
				          code ,
				          cost_flag ,
				          avg_cost ,
				          direct_dolrs ,
				          ovhd_dolrs ,
				          util_dolrs ,
				          err_msg ,
				          row_id
				        )
				VALUES  ( -1 , -- adj_no - int
				          @location, -- loc - varchar(10)
				          @part_no , -- part_no - varchar(30)
				          @bin_no, -- bin_no - varchar(12)
				          '1' , -- lot_ser - varchar(25)
				          GETDATE() , -- date_exp - datetime
				          @qty , -- qty - decimal
				          @direction , -- direction - int
				          'Inv Adj' , -- who_entered - varchar(50)
				          '' , -- reason_code - varchar(10)
				          '' , -- code - varchar(8)
				          '' , -- cost_flag - char(1)
				          NULL , -- avg_cost - decimal
				          NULL , -- direct_dolrs - decimal
				          NULL , -- ovhd_dolrs - decimal
				          NULL , -- util_dolrs - decimal
				          'Not enough qty in bin. Only have '+CAST(ISNULL(@bin_qty,0) AS VARCHAR(20)) , -- err_msg - varchar(255)
				          0  -- row_id - int
				        )
						SELECT @qty = ISNULL(@bin_qty,@qty)
		end

        IF @qty > 0
		begin
			INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 									
			VALUES(@location, @part_no, @bin_no, '1', GETDATE()+365, @qty, @direction,'Inv Adj', @reason_code, @code)

			-- SELECT * FROM #adm_inv_adj

			EXEC dbo.tdc_adm_inv_adj 

			INSERT INTO #adm_inv_adj_log
			SELECT * FROM #adm_inv_adj
		end

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@part_no = part_no,
				@bin_no = bin_no,
				@qty = qty
		FROM	#cvo_inv_adj
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END

	SELECT * FROM #adm_inv_adj_log
	
	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj  
	END
	
		IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj_log')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj_log
	END	

	IF (SELECT COUNT(*) FROM cvo_upc_upload) > 0 TRUNCATE TABLE CVO_UPC_UPLOAD

END

GO
GRANT EXECUTE ON  [dbo].[cvo_upc_upload_sp] TO [public]
GO
