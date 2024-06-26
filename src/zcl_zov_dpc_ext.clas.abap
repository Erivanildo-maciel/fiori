class ZCL_ZOV_DPC_EXT definition
  public
  inheriting from ZCL_ZOV_DPC
  create public .

public section.
protected section.

  methods MENSAGEMSET_CREATE_ENTITY
    redefinition .
  methods MENSAGEMSET_DELETE_ENTITY
    redefinition .
  methods MENSAGEMSET_GET_ENTITY
    redefinition .
  methods MENSAGEMSET_GET_ENTITYSET
    redefinition .
  methods MENSAGEMSET_UPDATE_ENTITY
    redefinition .
  methods OVCABSET_CREATE_ENTITY
    redefinition .
  methods OVCABSET_DELETE_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITYSET
    redefinition .
  methods OVCABSET_UPDATE_ENTITY
    redefinition .
  methods OVITEMSET_CREATE_ENTITY
    redefinition .
  methods OVITEMSET_DELETE_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITYSET
    redefinition .
  methods OVITEMSET_UPDATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZOV_DPC_EXT IMPLEMENTATION.


  method MENSAGEMSET_CREATE_ENTITY.

  endmethod.


  method MENSAGEMSET_DELETE_ENTITY.

  endmethod.


  method MENSAGEMSET_GET_ENTITY.

  endmethod.


  method MENSAGEMSET_GET_ENTITYSET.

  endmethod.


  method MENSAGEMSET_UPDATE_ENTITY.

  endmethod.


  METHOD ovcabset_create_entity.
    DATA: ld_lastid TYPE int4.
    DATA: ls_cab    TYPE zovcab.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    MOVE-CORRESPONDING er_entity TO ls_cab.

    ls_cab-data_criacao = sy-datum.
    ls_cab-hora_criacao = sy-uzeit.
    ls_cab-criado_por   = sy-uname.

    SELECT SINGLE MAX( ordemid )
      INTO ld_lastid
      FROM zovcab.

    ls_cab-ordemid = ld_lastid + 1.
    INSERT zovcab FROM ls_cab.
    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir ordem'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    " atualizando
    MOVE-CORRESPONDING ls_cab TO er_entity.

    CONVERT
      DATE ls_cab-data_criacao
      TIME ls_cab-hora_criacao
      INTO TIME STAMP er_entity-datacriacao
      TIME ZONE 'UTC'. "sy-zonlo.
  ENDMETHOD.


  method OVCABSET_DELETE_ENTITY.

  endmethod.


  METHOD ovcabset_get_entity.

    DATA: lv_ordemid TYPE zovcab-ordemid.
    DATA: ls_key_tab LIKE LINE OF it_key_tab.
    DATA: ls_cab TYPE zovcab.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.
    IF sy-subrc <> 0.

      lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'ID da Ordem não Informado!'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    lv_ordemid = ls_key_tab-value.

    SELECT SINGLE *
      FROM zovcab
      INTO ls_cab
     WHERE ordemid = lv_ordemid.

    IF sy-subrc = 0 .

      MOVE-CORRESPONDING ls_cab TO er_entity.

      er_entity-criadopor  = ls_cab-criado_por.
      er_entity-totalitens = ls_cab-total_itens.
      er_entity-totalfrete = ls_cab-total_frete.
      er_entity-totalordem = ls_cab-total_ordem.

      CONVERT
         DATE ls_cab-data_criacao
         TIME ls_cab-hora_criacao
         INTO TIME STAMP er_entity-datacriacao
         TIME ZONE sy-zonlo.

    ELSE.

      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Ordem Não encontrada!'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

  ENDMETHOD.


  METHOD ovcabset_get_entityset.

    DATA: lt_cab TYPE TABLE OF zovcab.
    DATA: ls_cab TYPE zovcab.
    DATA: ls_entityset LIKE LINE OF et_entityset.

    DATA: lt_orderby TYPE STANDARD TABLE OF string.
    DATA: lv_orderby TYPE string.

    LOOP AT it_order INTO DATA(ls_order).
      TRANSLATE ls_order-property TO UPPER CASE.
      TRANSLATE ls_order-order TO UPPER CASE.

      IF ls_order-order = 'DESC'.
        ls_order-order = 'DESCENDING'.
      ELSE.
        ls_order-order = 'ASCENDING'.
      ENDIF.

      APPEND |{ ls_order-property } { ls_order-order }| TO   lt_orderby.

    ENDLOOP.

    CONCATENATE LINES OF lt_orderby INTO lv_orderby SEPARATED BY space.

    IF lv_orderby IS INITIAL.
      lv_orderby = 'OrdemId ASCENDING'.
    ENDIF.

    SELECT *
      FROM zovcab
     WHERE (iv_filter_string)
     ORDER BY (lv_orderby)
      INTO TABLE @lt_cab
        UP TO @is_paging-top ROWS
    OFFSET @is_paging-skip.



    LOOP AT lt_cab INTO ls_cab.
      CLEAR ls_entityset.

      MOVE-CORRESPONDING ls_cab TO ls_entityset.

      ls_entityset-criadopor   = ls_cab-criado_por.
      ls_entityset-totalitens  = ls_cab-total_itens.
      ls_entityset-totalfrete  = ls_cab-total_frete.
      ls_entityset-totalordem  = ls_cab-total_ordem.

      CONVERT
         DATE ls_cab-data_criacao
         TIME ls_cab-hora_criacao
         INTO TIME STAMP ls_entityset-datacriacao
         TIME ZONE sy-zonlo.

      APPEND ls_entityset TO et_entityset.

    ENDLOOP.
  ENDMETHOD.


  METHOD ovcabset_update_entity.
*    DATA: ld_error TYPE flag.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    er_entity-ordemid = it_key_tab[ name = 'OrdemId' ]-value.

    " validações
*    IF er_entity-clienteid = 0.
**      ld_error = 'X'.
*      lo_msg->add_message_text_only(
*        EXPORTING
*          iv_msg_type = 'E'
*          iv_msg_text = 'Cliente vazio'
*      ).
*    ENDIF.

*    IF er_entity-totalordem < 10.
*      ld_error = 'X'.
*      lo_msg->add_message(
*        EXPORTING
*          iv_msg_type   = 'E'
*          iv_msg_id     = 'ZOV'
*          iv_msg_number = 1
*          iv_msg_v1     = 'R$ 10,00'
*          iv_msg_v2     = |{ er_entity-ordemid }|
*      ).
*    ENDIF.

*    IF ld_error = 'X'.
*      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*        EXPORTING
*          message_container = lo_msg
*          http_status_code  = 500.
*    ENDIF.

    UPDATE zovcab
       SET clienteid   = er_entity-clienteid
           total_itens = er_entity-totalitens
           total_frete = er_entity-totalfrete
           total_ordem = er_entity-totalordem
           status      = er_entity-status
     WHERE ordemid     = er_entity-ordemid.

    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao atualizar ordem'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

  ENDMETHOD.


  METHOD ovitemset_create_entity.
    DATA: ls_item TYPE zovitem.
    DATA: lv_max_item TYPE zovitem-itemid.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

*    MOVE-CORRESPONDING er_entity TO ls_item.
    ls_item-ordemid    = er_entity-ordemid.
    ls_item-material   = er_entity-material.
    ls_item-descricao  = er_entity-descricao.
    ls_item-quantidade = er_entity-quantidade.
    ls_item-preco_uni  = er_entity-precouni.
    ls_item-preco_tot  = er_entity-precotot.
    ls_item-mandt      = sy-mandt.

    IF er_entity-itemid = 0.
      SELECT SINGLE MAX( itemid )
        INTO er_entity-itemid
        FROM zovitem
       WHERE ordemid = er_entity-ordemid.

      er_entity-itemid = er_entity-itemid + 1.
      ls_item-itemid = er_entity-itemid.
    ENDIF.

    INSERT zovitem FROM ls_item.
    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir item'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.
  ENDMETHOD.


  method OVITEMSET_DELETE_ENTITY.

  endmethod.


  METHOD ovitemset_get_entity.

    DATA: ls_key_tab LIKE LINE OF it_key_tab.
    DATA: ls_item TYPE zovitem.
    DATA: lv_erro TYPE flag.
    DATA: lv_itemid TYPE zovitem-itemid.
    DATA: lv_ordemid TYPE zovitem-ordemid.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.
    IF sy-subrc <> 0.
      lv_erro = 'X'.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'ID da ordem não informado!'
      ).

    ENDIF.

    lv_ordemid =  ls_key_tab-value.

    READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'ItemId'.
    IF sy-subrc <> 0.
      lv_erro = 'X'.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'ID do item não informado!'
      ).
    ENDIF.

    lv_itemid = ls_key_tab-value.

    IF lv_erro = 'X'.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    SELECT SINGLE *
      FROM zovitem
      INTO ls_item
     WHERE ordemid = lv_ordemid
       AND itemid  = lv_itemid.

    IF sy-subrc = 0.

      MOVE-CORRESPONDING ls_item TO er_entity.

      er_entity-precouni = ls_item-preco_uni.
      er_entity-precotot = ls_item-preco_tot.

    ELSE.

      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Item não encontrado!'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

  ENDMETHOD.


  METHOD ovitemset_get_entityset.

    DATA: lv_ordemid TYPE int4.
    DATA: lr_ordemid_range TYPE RANGE OF int4.
    DATA: ls_ordemid_range LIKE LINE OF lr_ordemid_range.
    DATA: ls_key_tab LIKE LINE OF it_key_tab.

    READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.
    IF sy-subrc = 0.
      lv_ordemid = ls_key_tab-value.

      CLEAR ls_ordemid_range.
      ls_ordemid_range-sign = 'I'.
      ls_ordemid_range-option = 'EQ'.
      ls_ordemid_range-low = lv_ordemid.
      APPEND ls_ordemid_range TO lr_ordemid_range.


    ENDIF.

    SELECT *
      FROM zovitem
      INTO CORRESPONDING FIELDS OF TABLE et_entityset
     WHERE ordemid IN lr_ordemid_range.

  ENDMETHOD.


  METHOD ovitemset_update_entity.
    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    er_entity-ordemid  = it_key_tab[ name = 'OrdemId' ]-value.
    er_entity-itemid   = it_key_tab[ name = 'ItemId' ]-value.
    er_entity-precotot = er_entity-quantidade * er_entity-precouni.

    UPDATE zovitem
       SET material   = er_entity-material
           descricao  = er_entity-descricao
           quantidade = er_entity-quantidade
           preco_uni  = er_entity-precouni
           preco_tot  = er_entity-precotot
     WHERE ordemid    = er_entity-ordemid
       AND itemid     = er_entity-itemid.

    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao atualizar item'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
