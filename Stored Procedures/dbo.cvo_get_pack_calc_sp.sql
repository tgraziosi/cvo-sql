SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_get_pack_calc_sp] @order_total decimal(20,8)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@box			varchar(10),
			@box_capacity	decimal(20,8),
			@remainder		decimal(20,8),
			@result_id		int,
			@consumed		decimal(20,8),
			@left			decimal(20,8),
			@box_id			int,
			@curr_id		int,
			@max_id			int,
			@rank			int

	-- WORKING TABLES
	CREATE TABLE #results (
		result_id		int,
		box				varchar(10),
		box_capacity	int,
		qty				decimal(20,8),
		fill_perc		decimal(20,8),
		result_count	int,
		box_ranking		decimal(20,8)) -- v1.1

	CREATE TABLE #box_splits (
		box_id			int identity(1,1),
		box				varchar(10),
		box_capacity	int)

	CREATE TABLE #resultcount (
		result_id	int, 
		box_count	int)
	
	-- PROCESSING
	SET @box_capacity = 0
	SET @result_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @box = pkg_code,
				@box_capacity = pm_int_udef_f
		FROM	tdc_pkg_master (NOLOCK)
		WHERE	pm_int_udef_f > @box_capacity
		ORDER BY pm_int_udef_f ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		IF ((@order_total / @box_capacity) < 1)
		BEGIN
			SET @result_id = @result_id + 1

			SET @remainder = (@order_total / @box_capacity) * 100

			INSERT	#results
			SELECT	@result_id, @box, @box_capacity, @order_total, @remainder, 0, 0
		END
		ELSE
		BEGIN
			SET @result_id = @result_id + 1
			SET @left = @order_total

			SET @remainder = CAST(((@order_total / @box_capacity)) as int)
		
			WHILE (@remainder > 0)
			BEGIN
				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @box_capacity, 100, 0, 0

				SET @left = @left - @box_capacity
				SET @remainder = @remainder - 1	
			END

			IF (@left > 0)
			BEGIN
				SET @remainder = (@left / @box_capacity)
				IF (@remainder = 1)
					SET @remainder = 100

				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @left, @remainder, 0, 0
			END
		END 
	END

	INSERT	#box_splits (box, box_capacity)
	SELECT	pkg_code, pm_int_udef_f
	FROM	tdc_pkg_master (NOLOCK)
	WHERE	pm_int_udef_f <> 0
	ORDER BY pm_int_udef_f ASC

	SELECT @left = COUNT(1) FROM #box_splits
	SELECT @max_id = MAX(box_id) FROM #box_splits
	SET @box_id = 0

	WHILE (@left > 0)
	BEGIN
		SELECT	TOP 1 @box = box,
				@box_capacity = box_capacity,
				@box_id = box_id
		FROM	#box_splits
		WHERE	box_id > @box_id
		ORDER BY box_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK
	
		SET @remainder = @order_total

		SET @result_id = @result_id + 1					

		WHILE (@remainder > 0)
		BEGIN		
			IF (@remainder > @box_capacity)
			BEGIN 
				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @box_capacity, 100, 0, 0
				SET @remainder = @remainder - @box_capacity
			END
			ELSE
			BEGIN		
				SET @consumed = (@remainder / @box_capacity)
				IF (@consumed = 1)
					SET @consumed = 100
				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @remainder, @consumed, 0, 0
				SET @remainder = @remainder - @remainder
			END

			WHILE (@remainder > 0)
			BEGIN
				SELECT	TOP 1 @box = box,
						@box_capacity = box_capacity
				FROM	#box_splits
				WHERE	box_capacity >= @remainder
				ORDER BY box_capacity ASC

				IF (@remainder > @box_capacity)
				BEGIN 
					INSERT	#results
					SELECT	@result_id, @box, @box_capacity, @box_capacity, 100, 0, 0
					SET @remainder = @remainder - @box_capacity
				END
				ELSE
				BEGIN
					SET @consumed = (@remainder / @box_capacity)
					IF (@consumed = 1)
						SET @consumed = 100
					INSERT	#results
					SELECT	@result_id, @box, @box_capacity, @remainder, @consumed, 0, 0
					SET @remainder = @remainder - @remainder
				END
			END
		END
		SET @left = @left - 1
	END

	TRUNCATE TABLE #box_splits

	INSERT	#box_splits (box, box_capacity)
	SELECT	pkg_code, pm_int_udef_f
	FROM	tdc_pkg_master (NOLOCK)
	WHERE	pm_int_udef_f <> 0
	ORDER BY pm_int_udef_f DESC

	SELECT @left = COUNT(1) FROM #box_splits
	SELECT @max_id = MAX(box_id) FROM #box_splits
	SET @box_id = 0

	WHILE (@left > 0)
	BEGIN
		SELECT	TOP 1 @box = box,
				@box_capacity = box_capacity,
				@box_id = box_id
		FROM	#box_splits
		WHERE	box_id < @box_id
		ORDER BY box_id DESC

		IF (@@ROWCOUNT = 0)
			BREAK
	
		SET @remainder = @order_total

		SET @result_id = @result_id + 1					

		WHILE (@remainder > 0)
		BEGIN		
			IF (@remainder > @box_capacity)
			BEGIN 
				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @box_capacity, 100, 0, 0
				SET @remainder = @remainder - @box_capacity
			END
			ELSE
			BEGIN		
				SET @consumed = (@remainder / @box_capacity)
				IF (@consumed = 1)
					SET @consumed = 100
				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @remainder, @consumed, 0, 0
				SET @remainder = @remainder - @remainder
			END

			WHILE (@remainder > 0)
			BEGIN

				SELECT	TOP 1 @box = box,
						@box_capacity = box_capacity
				FROM	#box_splits
				WHERE	box_capacity >= @remainder
				ORDER BY box_capacity ASC

				SET @consumed = (@remainder / @box_capacity)
				IF (@consumed = 1)
					SET @consumed = 100
				INSERT	#results
				SELECT	@result_id, @box, @box_capacity, @remainder, @consumed, 0, 0
				SET @remainder = @remainder - @remainder
			END
		END
		SET @left = @left - 1
	END

	INSERT	#resultcount
	SELECT	result_id, count(box)
	FROM	#results
	GROUP BY result_id

	UPDATE	a
	SET		result_count = b.box_count
	FROM	#results a
	JOIN	#resultcount b
	ON		a.result_id = b.result_id

	-- v1.1 Start
	UPDATE	#results
	SET		box_ranking = (CASE WHEN fill_perc = 100 THEN 100 ELSE ((1 - fill_perc) * 100) END) * result_count -- v1.2
	-- v1.2 SET		box_ranking = CASE WHEN fill_perc = 100 THEN 100 ELSE ((1 - fill_perc) * 100) END

	SELECT	result_id, SUM(ABS(box_ranking)) ranking
	INTO	#temp2
	FROM	#results
	GROUP BY result_id

	UPDATE a
	SET box_ranking  = b.ranking
	FROM #results a
	JOIN #temp2 b
	ON a.result_id = b.result_id

	DROP TABLE #temp2

	UPDATE	#results
	SET		box_ranking = box_ranking + 100
	WHERE	 box_ranking < 100

	-- RETURN
	SELECT	TOP 1 @result_id = result_id
	FROM	#results
	ORDER BY box_ranking ASC -- v1.1
	-- v1.1 End

	INSERT	#pack_results (result_id, box, box_capacity, qty, fill_perc)
	SELECT	result_id, box, box_capacity, qty, fill_perc
	FROM	#results
	WHERE	result_id = @result_id
	ORDER BY box_capacity DESC

	-- CLEAN UP
	DROP TABLE #box_splits
	DROP TABLE #resultcount
	DROP TABLE #results

	RETURN @result_id

END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_pack_calc_sp] TO [public]
GO
