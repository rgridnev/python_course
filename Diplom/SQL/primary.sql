select agr.ISN                                                     agr_isn,
       agr.DATESIGN                                                agr_datesign,
       agr.DATEBEG                                                 agr_datebeg,
       agr.DATEEND                                                 agr_dateend,
       src.FULLNAME                                                agr_src,
       crtd.FULLNAME                                               agr_createdby,
       ins.ISN                                                     ins_isn,
       ins.FULLNAME                                                ins_name,
       ins_sh.SEX                                                  ins_sex,
       round(months_between(agr.DATEBEG, ins_sh.BIRTHDAY) / 12, 0) ins_year,
       decode(ins.JURIDICAL, 'Y', 1, 0)                            ins_jur,
       (select max(substr(decode(nvl(r.parentisn, 0), 0, r.OCATD, rr.OCATD), 1, 2)) keep (dense_rank first order by pr)
        from (select cc.regionisn, 2 pr
              from city cc
              where cc.isn = ins_addr.CITYISN
              union
              select nvl(c2.regionisn, r2.ISN), 1 pr
              from fias_addrobj f
                       left join city c2 on c2.gnicode = f.code
                       left join region r2 on r2.GNICODE = f.CODE
              where f.aoguid = ins_addr.FIASAOGUID
                and f.ACTSTATUS = 1) c
                 left join region r
                           on c.regionisn = r.ISN
                 left join region rr
                           on r.ParentISN = rr.isn
        where regionisn is not null)                               ins_reg,
       nvl(ins_sh.DOCSER, ins_doc.DOCSER)                          ins_DOCSER,
       own.ISN                                                     own_isn,
       own.FULLNAME                                                own_name,
       own_sh.SEX                                                  own_sex,
       round(months_between(agr.DATEBEG, own_sh.BIRTHDAY) / 12, 0) own_year,
       decode(own.JURIDICAL, 'Y', 1, 0)                            own_jur,
       (select max(substr(decode(nvl(r.parentisn, 0), 0, r.OCATD, rr.OCATD), 1, 2)) keep (dense_rank first order by pr)
        from (select cc.regionisn, 2 pr
              from city cc
              where cc.isn = own_addr.CITYISN
              union
              select nvl(c2.regionisn, r2.ISN), 1 pr
              from fias_addrobj f
                       left join city c2 on c2.gnicode = f.code
                       left join region r2 on r2.GNICODE = f.CODE
              where f.aoguid = own_addr.FIASAOGUID
                and f.ACTSTATUS = 1) c
                 left join region r
                           on c.regionisn = r.ISN
                 left join region rr
                           on r.ParentISN = rr.isn
        where regionisn is not null)                               own_reg,
       nvl(own_sh.DOCSER, own_doc.DOCSER)                          own_DOCSER,
       drv.NAME                                                    drv_name,
       drv.SEX                                                     drv_sex,
       drv.YEAR                                                    drv_year,
       drv.DOCSER                                                  drv_docser,
       drv.KBM                                                     drv_kbm,
       drv.SKILL                                                   drv_skill,
       to_char(kbm.NUMCODE, 'fm0.99')                              agr_kbm,
       drv.ISN                                                     drv_isn,
       tp.FULLNAME                                                 ts_type,
       cat.FULLNAME                                                ts_category,
       mrk.FULLNAME                                                ts_mark_name,
       mdl.FULLNAME                                                ts_model_name,
       to_char(aoc.RELEASEDATE, 'yyyy')                            ts_year,
       aoc.VIN                                                     ts_VIN,
       aoc.POWER                                                   ts_power,
       aoc.REGNO                                                   ts_regno,
       caruse.FULLNAME                                             ts_use_name,
       ts_doc.FULLNAME                                             ts_doc,
       aoc.PTSSER || ' ' || aoc.PTSNO                              ts_doc_ser_no,
       agr.PREVISN                                                 agr_previsn,
       (select a.ISN from agreement a where a.PREVISN = agr.ISN)   agr_nextisn,
       claim.cnt_not_pay                                           cnt_claim_not_pay,
       claim.cnt_pay                                               cnt_claim_pay,
       claim.sum_not_pay                                           sum_claim_not_pay,
       claim.sum_pay                                               sum_claim_pay,
       claim.cnt_pvu_not_pay                                       cnt_pvu_not_pay,
       claim.cnt_pvu_pay                                           cnt_pvu_pay,
       claim.sum_pvu_not_pay                                       sum_pvu_not_pay,
       claim.sum_pvu_pay                                           sum_pvu_pay,
       sign(court.cnt)                                             court_exists,
       court.AMOUNT                                                court_amount,
       decode(ins.VIP, 'N', 1, 0)                                  ins_anti_VIP,
       decode(own.VIP, 'N', 1, 0)                                  own_anti_VIP,
       drv.ANTI_VIP                                                drv_anti_vip
from AGREEMENT agr
         join dicti src on src.isn = agr.SYSTEMISN
         join SUBJECT crtd on crtd.isn = agr.CREATEDBY
         join subject ins on ins.ISN = agr.CLIENTISN
         join AGROBJECT ao on ao.AGRISN = agr.ISN
         join AGROBJCAR aoc on aoc.isn = ao.ISN
         join subject own on own.ISN = aoc.OWNERISN
         left join subhuman ins_sh on ins_sh.isn = ins.ISN and ins_sh.DOCCLASSISN = cnt.isn('kdPassportRF')
         left join subhuman own_sh on own_sh.isn = ins.ISN and own_sh.DOCCLASSISN = cnt.isn('kdPassportRF')
         left join dicti kbm on kbm.ISN = aoc.BONUSMALUSISN
         left join DICTI mdl on mdl.ISN = aoc.MODELISN
         left join DICTI mrk on mrk.isn = mdl.PARENTISN
         left join DICTI tp on tp.ISN = mrk.PARENTISN
         left join DICTI cat on cat.ISN = aoc.CATEGORYISN
         left join DICTI caruse on caruse.ISN = aoc.CARUSEISN
         left join DICTI ts_doc on ts_doc.isn = aoc.PTSCLASSISN
         outer apply (select sa.CITYISN, sa.FIASAOGUID
                      from SUBADDR sa
                      where sa.SUBJISN = agr.CLIENTISN
                        and sa.CLASSISN in (cnt.isn('cAddrReg'), cnt.ISN('cAddrJur'))
--                        and sa.UPDATED <= agr.DATESIGN
                      order by sa.UPDATED desc
                          fetch first row only) ins_addr
         outer apply (select sd.DOCSER
                      from SUBDOC sd
                      where sd.SUBJISN = agr.CLIENTISN
                        and sd.CLASSISN = cnt.isn('kdPassportRF')
                        and sd.UPDATED <= agr.DATESIGN
                      order by sd.UPDATED desc
                          fetch first row only) ins_doc
         outer apply (select sa.CITYISN, sa.FIASAOGUID
                      from SUBADDR sa
                      where sa.SUBJISN = aoc.OWNERISN
                        and sa.CLASSISN in (cnt.isn('cAddrReg'), cnt.ISN('cAddrJur'))
--                        and sa.UPDATED <= agr.DATESIGN
                      order by sa.UPDATED desc
                          fetch first row only) own_addr
         outer apply (select sd.DOCSER
                      from SUBDOC sd
                      where sd.SUBJISN = aoc.OWNERISN
                        and sd.CLASSISN = cnt.isn('kdPassportRF')
                        and sd.UPDATED <= agr.DATESIGN
                      order by sd.UPDATED desc
                          fetch first row only) own_doc
         outer apply (select listagg(s.ISN, ',') within group (order by s.FULLNAME)                          ISN,
                             listagg(s.FULLNAME, ',') within group (order by s.FULLNAME)                     NAME,
                             listagg(to_char(kbm.NUMCODE, 'fm0.99'), ',') within group (order by s.FULLNAME) KBM,
                             listagg(nvl(decode(sh.DOCCLASSISN, cnt.isn('kdDriveLicen'), sh.DOCSER, null), ser.DOCSER),
                                     ',') within group (order by s.FULLNAME)                                 DOCSER,
                             listagg(decode(s.VIP, 'N', 1, 0), ',') within group (order by s.FULLNAME)       ANTI_VIP,
                             listagg(sh.SEX, ',') within group (order by s.FULLNAME)                         SEX,
                             listagg(round(months_between(agr.DATEBEG, sh.BIRTHDAY) / 12, 0), ',')
                                     within group (order by s.FULLNAME)                                      YEAR,
                             listagg(round(months_between(agr.DATEBEG, sh.DRIVINGDATEBEG) / 12, 0), ',')
                                     within group (order by s.FULLNAME)                                      SKILL
                      from AGRROLE ar
                               join subject s on s.isn = ar.SUBJISN
                               join dicti kbm on kbm.ISN = ar.BONUSMALUSISN
                               left join SUBHUMAN sh on sh.isn = s.ISN --and sh.DOCCLASSISN = cnt.isn('kdDriveLicen')
                               outer apply (select sd.DOCSER
                                            from subdoc sd
                                            where sd.SUBJISN = s.isn
                                              and sd.CLASSISN = cnt.isn('kdDriveLicen')
                                              -- and sd.UPDATED <= agr.DATESIGN
                                            order by sd.UPDATED desc
                                                fetch first row only) ser
                      where ar.AGRISN = agr.ISN
                        and ar.CLASSISN = 2085) drv
         outer apply (select count(case
                                       when exists(select 1
                                                   from AGRSUM ags
                                                   where ags.CLAIMISN = ac.ISN
                                                     and ags.AGRISN = ac.AGRISN
                                                     and ags.CLASSISN = 2003
                                                     and ags.CLASSISN2 = 2501
                                                     and ags.DISCR = 'F') then 1
                                       else null end) cnt_pay,
                             count(case
                                       when not exists(select 1
                                                       from AGRSUM ags
                                                       where ags.CLAIMISN = ac.ISN
                                                         and ags.AGRISN = ac.AGRISN
                                                         and ags.CLASSISN = 2003
                                                         and ags.CLASSISN2 = 2501
                                                         and ags.DISCR = 'F') then 1
                                       else null end) cnt_not_pay,
                             sum(case
                                     when exists(select 1
                                                 from AGRSUM ags
                                                 where ags.CLAIMISN = ac.ISN
                                                   and ags.AGRISN = ac.AGRISN
                                                   and ags.CLASSISN = 2003
                                                   and ags.CLASSISN2 = 2501
                                                   and ags.DISCR = 'F') then ac.CLAIMSUM
                                     else 0 end)      sum_pay,
                             sum(case
                                     when not exists(select 1
                                                     from AGRSUM ags
                                                     where ags.CLAIMISN = ac.ISN
                                                       and ags.AGRISN = ac.AGRISN
                                                       and ags.CLASSISN = 2003
                                                       and ags.CLASSISN2 = 2501
                                                       and ags.DISCR = 'F') then ac.CLAIMSUM
                                     else 0 end)      sum_not_pay,
                             count(case
                                       when exists(select 1
                                                   from AGRSUM ags
                                                   where ags.CLAIMISN = ac.ISN
                                                     and ags.AGRISN = ac.AGRISN
                                                     and ags.CLASSISN = 2003
                                                     and ags.CLASSISN2 = 2501
                                                     and ags.DISCR = 'F') and ac.CLASSISN = 220215 then 1
                                       else null end) cnt_pvu_pay,
                             count(case
                                       when not exists(select 1
                                                       from AGRSUM ags
                                                       where ags.CLAIMISN = ac.ISN
                                                         and ags.AGRISN = ac.AGRISN
                                                         and ags.CLASSISN = 2003
                                                         and ags.CLASSISN2 = 2501
                                                         and ags.DISCR = 'F') and ac.CLASSISN = 220215 then 1
                                       else null end) cnt_pvu_not_pay,
                             sum(case
                                     when exists(select 1
                                                 from AGRSUM ags
                                                 where ags.CLAIMISN = ac.ISN
                                                   and ags.AGRISN = ac.AGRISN
                                                   and ags.CLASSISN = 2003
                                                   and ags.CLASSISN2 = 2501
                                                   and ags.DISCR = 'F') and ac.CLASSISN = 220215 then ac.CLAIMSUM
                                     else 0 end)      sum_pvu_pay,
                             sum(case
                                     when not exists(select 1
                                                     from AGRSUM ags
                                                     where ags.CLAIMISN = ac.ISN
                                                       and ags.AGRISN = ac.AGRISN
                                                       and ags.CLASSISN = 2003
                                                       and ags.CLASSISN2 = 2501
                                                       and ags.DISCR = 'F') and ac.CLASSISN = 220215 then ac.CLAIMSUM
                                     else 0 end)      sum_pvu_not_pay,
                             nvl(sum(ac.CLAIMSUM), 0) claim_sum
                      from agrclaim ac
                      where ac.AGRISN = agr.ISN
                        and ac.STATUS <> 'A') claim
         outer apply (select sum(dcs.AMOUNT) AMOUNT, count(dcs.ISN) cnt
                      from docs d
                               join agrrefund ar on d.REFUNDISN = ar.ISN
                               join DocCourt dc on dc.ISN = d.isn
                               join DocCourtSum dcs on dcs.DOCISN = d.ISN
                      where ar.AGRISN = agr.ISN
                        and d.CLASSISN = 220101--судебный иск
                        and d.STATUSISN <> cnt.ISN('cDocStateDestroy')
                        and dc.LEGALSTATUSISN in
                            (cnt.isn('cLegalStatusDefendant'), cnt.isn('cLegalStatusCoDefendant'))) court
where agr.PRODUCTISN = 3387
  -- подписанные после 01.01.2015
  and agr.DATESIGN >= to_date('01.01.2015', 'dd.mm.yyyy')
  -- закончившиеся на момент формирования выгрузки
  and agr.DATEEND <= sysdate
  -- Давай аннулированные уберем
  and agr.STATUS <> 'А'
  --and agr.isn = 888687974;


