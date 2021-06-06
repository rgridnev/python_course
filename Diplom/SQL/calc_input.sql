select agr.ISN                                                                      agr_isn,
       agr.DATESIGN                                                                 agr_datesign,
       agr.DATEBEG                                                                  agr_datebeg,
       agr.DATEEND                                                                  agr_dateend,
       src.FULLNAME                                                                 agr_src,
       crtd.FULLNAME                                                                agr_createdby,
       ins.ISN                                                                      ins_isn,
       ins.FULLNAME                                                                 ins_name,
       ins.SEX                                                                      ins_sex,
       round(months_between(agr.DATEBEG, ins.BIRTHDAY) / 12, 2)                     ins_year,
       decode(ins.JURIDICAL, 'Y', 1, 0)                                             ins_jur,
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
        where regionisn is not null)                                                ins_reg,
       decode(ins.docclassisn, cnt.isn('kdPassportRF'), ins.DOCSER, ins_doc.DOCSER) ins_DOCSER,
       own.ISN                                                                      own_isn,
       own.FULLNAME                                                                 own_name,
       own.SEX                                                                      own_sex,
       round(months_between(agr.DATEBEG, own.BIRTHDAY) / 12, 2)                     own_year,
       decode(own.JURIDICAL, 'Y', 1, 0)                                             own_jur,
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
        where regionisn is not null)                                                own_reg,
       decode(own.docclassisn, cnt.isn('kdPassportRF'), own.DOCSER, own_doc.DOCSER) own_DOCSER,
       drv.NAME                                                                     drv_name,
       drv.SEX                                                                      drv_sex,
       drv.YEAR                                                                     drv_year,
       drv.DOCSER                                                                   drv_docser,
       drv.KBM                                                                      drv_kbm,
       to_char(kbm.NUMCODE, 'fm0.00')                                               agr_kbm,
       drv.ISN                                                                      drv_isn,
       tp.FULLNAME                                                                  ts_type,
       cat.FULLNAME                                                                 ts_category,
       mrk.FULLNAME                                                                 ts_mark_name,
       mdl.FULLNAME                                                                 ts_model_name,
       to_char(aoc.RELEASEDATE, 'yyyy')                                             ts_year,
       aoc.VIN                                                                      ts_VIN,
       aoc.POWER                                                                    ts_power,
       aoc.REGNO                                                                    ts_regno,
       caruse.FULLNAME                                                              ts_use_name,
       ts_doc.FULLNAME                                                              ts_doc,
       aoc.PTSSER || ' ' || aoc.PTSNO                                               ts_doc_ser_no,
       agr.PREVISN                                                                  agr_previsn,
       decode(prem.PremiumSum, 0, 'N', 'Y')                                         pass_scoring,
       prem.PremiumSum                                                              PremiumSum
from AGREEMENTCALC agr
         join dicti src on src.isn = agr.SYSTEMISN
         join SUBJECT crtd on crtd.isn = agr.CREATEDBY
         join V_CALCSUBJECT ins on ins.ISN = agr.CLIENTISN
         join AGROBJECT ao on ao.AGRISN = agr.ISN
         join AGROBJCAR aoc on aoc.isn = ao.ISN
         join V_CALCSUBJECT own on own.ISN = aoc.OWNERISN
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
                        --and sa.UPDATED <= agr.DATESIGN
                      order by sa.UPDATED desc
                          fetch first row only) ins_addr
         outer apply (select sd.DOCSER
                      from SUBDOC sd
                      where sd.SUBJISN = agr.CLIENTISN
                        and sd.CLASSISN = cnt.isn('kdPassportRF')
                        --and sd.UPDATED <= agr.DATESIGN
                      order by sd.UPDATED desc
                          fetch first row only) ins_doc
         outer apply (select sa.CITYISN, sa.FIASAOGUID
                      from SUBADDR sa
                      where sa.SUBJISN = aoc.OWNERISN
                        and sa.CLASSISN in (cnt.isn('cAddrReg'), cnt.ISN('cAddrJur'))
                        --and sa.UPDATED <= agr.DATESIGN
                      order by sa.UPDATED desc
                          fetch first row only) own_addr
         outer apply (select sd.DOCSER
                      from SUBDOC sd
                      where sd.SUBJISN = aoc.OWNERISN
                        and sd.CLASSISN = cnt.isn('kdPassportRF')
                        --and sd.UPDATED <= agr.DATESIGN
                      order by sd.UPDATED desc
                          fetch first row only) own_doc
         outer apply (select listagg(s.ISN, ',') within group (order by s.FULLNAME)                          ISN,
                             listagg(s.FULLNAME, ',') within group (order by s.FULLNAME)                     NAME,
                             listagg(to_char(kbm.NUMCODE, 'fm0.00'), ',') within group (order by s.FULLNAME) KBM,
                             listagg(nvl(s.DRIVINGDOCSER, ser.DOCSER),
                                     ',') within group (order by s.FULLNAME)                                 DOCSER,
                             listagg(s.SEX, ',') within group (order by s.FULLNAME)                          SEX,
                             listagg(round(months_between(agr.DATEBEG, s.BIRTHDAY) / 12, 2), ', ')
                                     within group (order by s.FULLNAME)                                      YEAR
                      from AGRROLE ar
                               join V_CALCSUBJECT s on s.isn = ar.SUBJISN
                               join dicti kbm on kbm.ISN = ar.BONUSMALUSISN
                               outer apply (select sd.DOCSER
                                            from subdoc sd
                                            where sd.SUBJISN = s.isn
                                              and sd.CLASSISN = cnt.isn('kdDriveLicen')
                                              -- and sd.UPDATED <= agr.DATESIGN
                                            order by sd.UPDATED desc
                                                fetch first row only) ser
                      where ar.AGRISN = agr.ISN
                        and ar.CLASSISN = 2085) drv
         outer apply (SELECT nvl(SUM(PremiumSum), 0) PremiumSum
                      FROM AgrCond n
                      WHERE n.AgrISN = agr.ISN) prem

where agr.PRODUCTISN = 3387
  -- за последние 30 дней
  and agr.DATESIGN >= trunc(sysdate) - 30

--and agr.isn = 888687974;


