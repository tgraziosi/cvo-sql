SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_inv_upd_util_sp] @user_spid		int,
									@process		int,
									@process_user	varchar(50) = NULL
AS
BEGIN

	IF (@process = 0) -- Validate 
	BEGIN

		
		UPDATE	a
		SET		part_no = b.part_no
		FROM	cvo_inv_upd_util a
		JOIN	uom_id_code b (NOLOCK)
		ON		a.sku = b.upc
		WHERE	a.user_spid = @user_spid

	-- in case part # is in there
		UPDATE	a
		SET		part_no = b.part_no
		FROM	cvo_inv_upd_util a
		JOIN	uom_id_code b (NOLOCK)
		ON		a.sku = b.part_no
		WHERE	a.user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid SKU' ELSE '; Invalid SKU' END,
				error_flag = 1
		WHERE	part_no IS NULL
		AND		user_spid = @user_spid

		UPDATE	a
		SET		line_message = line_message + CASE WHEN a.line_message = '' THEN 'Part Void' ELSE '; Part Void' END,
				error_flag = 1
		FROM	cvo_inv_upd_util a
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	b.void = 'V'
		AND		user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid value for Obsolete' ELSE '; Invalid valid for Obsolete' END,
				error_flag = 1
		WHERE	obsolete_str <> ''
		AND		UPPER(ISNULL(obsolete_str,'')) NOT IN ('Y','N') 
		AND		user_spid = @user_spid
		
		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid value for web saleable' ELSE '; Invalid value for web saleable' END,
				error_flag = 1
		WHERE	web_sellable <> ''
		AND		UPPER(ISNULL(web_sellable,'')) NOT IN ('Y','N') 
		AND		user_spid = @user_spid

		-- Don't Allow Retail and HVC items to be web-sellable
		UPDATE	a
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid sku for web saleable' ELSE '; Invalid sku for web saleable' END,
				error_flag = 1
		FROM	cvo_inv_upd_util a
		JOIN	inv_master_add b (NOLOCK) ON b.part_no = a.part_no
		WHERE	web_sellable ='Y' AND ISNULL(b.field_32,'') IN ('RETAIL','HVC')
		AND		user_spid = @user_spid
	
	
		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid value for watch' ELSE '; Invalid value for watch' END,
				error_flag = 1
		WHERE	watch <> ''
		AND		UPPER(ISNULL(watch,'')) NOT IN ('Y','N') 
		AND		user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid pom date' ELSE '; Invalid for pom date' END,
				error_flag = 1
		WHERE	pom_date_str <> ''
		AND		UPPER(pom_date_str) <> 'NONE' -- v1.1
		AND		ISDATE(pom_date_str) <> 1
		AND		user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid mix of POM and Watch' ELSE '; Invalid mix of POM and Watch' END,
				error_flag = 1
		WHERE	ISNULL(watch,'') ='Y' AND ISDATE(pom_date_str) = 1
		AND		user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid release date' ELSE '; Invalid for release date' END,
				error_flag = 1
		WHERE	release_date_str <> ''
		AND		ISDATE(release_date_str) <> 1
		AND		user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		line_message = line_message + CASE WHEN line_message = '' THEN 'Invalid backorder date' ELSE '; Invalid for backorder date' END,
				error_flag = 1
		WHERE	backorder_date_str <> ''
		AND		UPPER(backorder_date_str) <> 'NONE' -- v1.1
		AND		ISDATE(backorder_date_str) <> 1
		AND		user_spid = @user_spid

		UPDATE	cvo_inv_upd_util
		SET		obsolete = CASE WHEN UPPER(obsolete_str) = 'Y' THEN 1 ELSE 0 END
		WHERE	obsolete_str <> ''
		AND		user_spid = @user_spid
		AND		error_flag = 0

		UPDATE	a
		SET		line_message = line_message + CASE WHEN a.obsolete = 1 AND ISNULL(b.obsolete,0) = 0 THEN 
										CASE WHEN a.line_message = '' THEN 'Obsolete: Off to On' ELSE '; Obsolete: Off to On' END
									WHEN a.obsolete = 0 AND ISNULL(b.obsolete,0) = 1 THEN
										CASE WHEN a.line_message = '' THEN 'Obsolete: On to Off' ELSE '; Obsolete: On to Off' END
								ELSE
									CASE WHEN a.line_message = '' THEN 'Obsolete: No Change' ELSE '; Obsolete: No Change' END
								END
		FROM	cvo_inv_upd_util a
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.obsolete_str <> ''
		AND		a.user_spid = @user_spid
		AND		error_flag = 0

		UPDATE	a
		SET		line_message = line_message + CASE WHEN UPPER(a.web_sellable) = 'Y' AND ISNULL(UPPER(b.web_saleable_flag),'N') = 'N' THEN 
										CASE WHEN a.line_message = '' THEN 'Web Saleable: Off to On' ELSE '; Web Saleable: Off to On' END
									WHEN UPPER(a.web_sellable) = 'N' AND ISNULL(UPPER(b.web_saleable_flag),'N') = 'Y' THEN
										CASE WHEN a.line_message = '' THEN 'Web Saleable: On to Off' ELSE '; Web Saleable: On to Off' END
								ELSE
									CASE WHEN a.line_message = '' THEN 'Web Saleable: No Change' ELSE '; Web Saleable: No Change' END
								END
		FROM	cvo_inv_upd_util a
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.web_sellable <> ''
		AND		a.user_spid = @user_spid
		AND		a.error_flag = 0

		UPDATE	a
		SET		line_message = line_message + CASE WHEN UPPER(a.watch) = 'Y' AND ISNULL(UPPER(b.category_1),'N') = 'N' THEN 
										CASE WHEN a.line_message = '' THEN 'Watch: Off to On' ELSE '; Watch: Off to On' END
									WHEN UPPER(a.watch) = 'N' AND ISNULL(UPPER(b.category_1),'N') = 'Y' THEN
										CASE WHEN a.line_message = '' THEN 'Watch: On to Off' ELSE '; Watch: On to Off' END
								ELSE
									CASE WHEN a.line_message = '' THEN 'Watch: No Change' ELSE '; Watch: No Change' END
								END
		FROM	cvo_inv_upd_util a
		JOIN	inv_master_add b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.watch <> ''
		AND		a.user_spid = @user_spid
		AND		a.error_flag = 0

		UPDATE dbo.cvo_inv_upd_util
		SET backorder_date_str = pom_date_str 
		WHERE UPPER(pom_date_str) = 'NONE'

		UPDATE	cvo_inv_upd_util
		SET		pom_date = CONVERT(DATETIME,pom_date_str)
		-- force the backorder date values
				, backorder_date = DATEADD(m,3,CONVERT(DATETIME,pom_date_str))
				, backorder_date_str = CONVERT(VARCHAR(10), DATEADD(mm,3,CONVERT(DATETIME,pom_date_str)), 101)
		-- If POM date turned on the sku must not have watch set 
				, watch = 'N'
		WHERE	pom_date_str <> ''
		AND		UPPER(pom_date_str) <> 'NONE' -- v1.1
		AND		user_spid = @user_spid
		AND		error_flag = 0

		
		UPDATE	a
		SET		line_message = line_message + CASE WHEN a.line_message = '' THEN 'POM Date Change: ' ELSE '; POM Date Change: ' END +
												CASE WHEN UPPER(a.pom_date_str) = 'NONE' THEN -- v1.1
													CASE WHEN b.field_28 IS NULL THEN 'No Change' -- v1.1
													ELSE CONVERT(varchar(10),b.field_28,101) + ' To Not Set' END -- v1.1
												ELSE
												CASE WHEN b.field_28 IS NULL THEN 'Not Set To ' + CONVERT(varchar(10),a.pom_date,101)
													WHEN CONVERT(varchar(10),b.field_28,101) = CONVERT(varchar(10),a.pom_date,101) THEN 'No Change'
													ELSE CONVERT(varchar(10),b.field_28,101) + ' To ' + CONVERT(varchar(10),a.pom_date,101) END
												END,
		-- if setting or changing a pom date, watch has to be set to No
-- 060716 tag - watch is category_1, not category_2
--				watch = CASE WHEN a.pom_date_str NOT IN ('','NONE') THEN 'N' ELSE ISNULL(b.category_2,'N') END
				watch = CASE WHEN a.pom_date_str NOT IN ('','NONE') THEN 'N' ELSE ISNULL(b.category_1,'N') END
	
		FROM	cvo_inv_upd_util a
		JOIN	inv_master_add b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.pom_date_str <> ''
		AND		a.user_spid = @user_spid
		AND		a.error_flag = 0

		UPDATE	cvo_inv_upd_util
		SET		release_date = CONVERT(DATETIME,release_date_str)
		WHERE	release_date_str <> ''
		AND		user_spid = @user_spid
		AND		error_flag = 0

		UPDATE	a
		SET		line_message = line_message + CASE WHEN a.line_message = '' THEN 'Release Date Change: ' ELSE '; Release Date Change: ' END +
												CASE WHEN b.field_26 IS NULL THEN 'Not Set To ' 
													WHEN CONVERT(varchar(10),b.field_26,101) = CONVERT(varchar(10),a.release_date,101) THEN 'No Change'
													ELSE CONVERT(varchar(10),b.field_26,101) + ' To ' + CONVERT(varchar(10),a.release_date,101) END
		FROM	cvo_inv_upd_util a
		JOIN	inv_master_add b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.release_date_str <> ''
		AND		a.user_spid = @user_spid
		AND		a.error_flag = 0
	
		UPDATE	cvo_inv_upd_util
		SET		backorder_date = CONVERT(DATETIME,backorder_date_str)
		WHERE	backorder_date_str <> ''
		AND		UPPER(backorder_date_str) <> 'NONE' -- v1.1
		AND		user_spid = @user_spid
		AND		error_flag = 0

		UPDATE	a
		SET		line_message = line_message + CASE WHEN a.line_message = '' THEN 'Backorder Date Change: ' ELSE '; Backorder Date Change: ' END +
												CASE WHEN UPPER(a.backorder_date_str) = 'NONE' THEN -- v1.1
													CASE WHEN b.datetime_2 IS NULL THEN 'No Change' -- v1.1
													ELSE CONVERT(varchar(10),b.datetime_2,101) + ' To Not Set' END -- v1.1
												ELSE
												CASE WHEN b.datetime_2 IS NULL THEN 'Not Set To ' 
													WHEN CONVERT(varchar(10),b.datetime_2,101) = CONVERT(varchar(10),a.backorder_date,101) THEN 'No Change'
													ELSE CONVERT(varchar(10),b.datetime_2,101) + ' To ' + CONVERT(varchar(10),a.backorder_date,101) END
												END
		FROM	cvo_inv_upd_util a
		JOIN	inv_master_add b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.backorder_date_str <> ''
		AND		a.user_spid = @user_spid
		AND		a.error_flag = 0

		UPDATE	cvo_inv_upd_util
		SET		process_flag = 1
		WHERE	user_spid = @user_spid
		AND		error_flag = 0

		UPDATE	cvo_inv_upd_util
		SET		obsolete_str = ISNULL(obsolete_str,''),
				web_sellable = ISNULL(web_sellable,''),
				pom_date_str = ISNULL(pom_date_str,''),
				release_date_str = ISNULL(release_date_str,''),
				watch = ISNULL(watch,''),
				backorder_date_str = ISNULL(backorder_date_str,'')
		WHERE	user_spid = @user_spid

	END	

	IF (@process = 1)
	BEGIN
	
		INSERT	cvo_inv_upd_util_audit (sku, part_no, process_user, process_date, line_message)
		SELECT	sku, part_no, @process_user, getdate(), line_message
		FROM	cvo_inv_upd_util
		WHERE	user_spid = @user_spid
		AND		process_flag = 1

		UPDATE	a
		SET		obsolete = CASE WHEN b.obsolete_str = '' THEN a.obsolete ELSE b.obsolete END,
				web_saleable_flag = CASE WHEN b.web_sellable = '' THEN a.web_saleable_flag ELSE b.web_sellable END
		FROM	inv_master a
		JOIN	cvo_inv_upd_util b
		ON		a.part_no = b.part_no
		WHERE	b.user_spid = @user_spid
		AND		b.process_flag = 1
		AND		(b.obsolete_str <> '' OR web_sellable <> '')

		UPDATE	a
		SET		field_28 = CASE b.pom_date_str WHEN '' THEN a.field_28 WHEN 'NONE' THEN NULL ELSE b.pom_date END, -- v1.1
				field_26 = CASE b.release_date_str WHEN '' THEN a.field_26 ELSE b.release_date END,
				category_1 = CASE WHEN b.watch = '' THEN a.category_1 ELSE b.watch END,
				datetime_2 = CASE b.backorder_date_str WHEN '' THEN a.datetime_2 WHEN 'NONE' THEN NULL ELSE b.backorder_date END -- v1.1
		FROM	inv_master_add a
		JOIN	cvo_inv_upd_util b
		ON		a.part_no = b.part_no
		WHERE	b.user_spid = @user_spid
		AND		b.process_flag = 1
		AND		(b.pom_date_str <> '' OR release_date_str <> '' OR watch <> '' OR backorder_date_str <> '')

	END

END



GO
GRANT EXECUTE ON  [dbo].[cvo_inv_upd_util_sp] TO [public]
GO
