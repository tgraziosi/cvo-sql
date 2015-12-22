CREATE TABLE [dbo].[gl_glesldet]
(
[timestamp] [timestamp] NOT NULL,
[esl_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_id] [int] NOT NULL,
[err_code] [int] NOT NULL,
[num_of_trx] [int] NOT NULL,
[to_ctry_code_vat] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_rpt] [float] NOT NULL,
[indicator_esl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [glesldet_0] ON [dbo].[gl_glesldet] ([esl_ctrl_num], [line_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glesldet] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glesldet] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glesldet] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glesldet] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glesldet] TO [public]
GO
