<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %><c:set var="rolNecesario" value="ADMINISTRADOR"/><%@ include file="/WEB-INF/jspf/roles.jspf" %>
<%-- Gestión de cuentas: confirma la escritura y comprueba el mismo hash que utiliza login.jsp.
     Importante: la auditoría es independiente; un fallo suyo no anula un alta ya confirmada. --%>
<c:if test="${pageContext.request.method eq 'POST'}">
  <c:choose>
    <c:when test="${empty sessionScope.csrf or param.csrf ne sessionScope.csrf}">
      <c:set var="mensajeError" value="La sesión de administración venció. Actualiza la página e inténtalo nuevamente."/>
    </c:when>
    <c:when test="${param.accion eq 'normalizar_utf8'}">
      <%-- Normaliza únicamente secuencias típicas de UTF-8 mal interpretadas en nombres y programas.
           Se ejecuta bajo demanda por el administrador; no toca correo, claves, ID o roles. --%>
      <c:catch var="errorNormalizarUtf8">
        <sql:update var="filasNormalizadas" dataSource="${db}">
          UPDATE parcial_julian.usuarios
          SET programa = replace(replace(replace(replace(replace(replace(programa,
                        'Ã¡','á'),'Ã©','é'),'Ã­','í'),'Ã³','ó'),'Ãº','ú'),'Ã±','ñ'),
              nombre = replace(replace(replace(replace(replace(replace(nombre,
                        'Ã¡','á'),'Ã©','é'),'Ã­','í'),'Ã³','ó'),'Ãº','ú'),'Ã±','ñ')
          WHERE programa LIKE '%Ã%' OR nombre LIKE '%Ã%'
        </sql:update>
      </c:catch>
      <c:choose>
        <c:when test="${not empty errorNormalizarUtf8}">
          <c:set var="mensajeError" value="No fue posible corregir los textos anteriores en la base de datos."/>
        </c:when>
        <c:otherwise><c:redirect url="/usuarios.jsp?ok=utf8"/></c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${param.accion eq 'crear'}">
      <c:choose>
        <c:when test="${empty fn:trim(param.nombre)}">
          <c:set var="mensajeError" value="Ingresa el nombre completo del usuario."/>
        </c:when>
        <c:when test="${empty fn:trim(param.correo)}">
          <c:set var="mensajeError" value="Ingresa el correo electrónico del usuario."/>
        </c:when>
        <c:when test="${empty param.clave or fn:length(param.clave) lt 8}">
          <c:set var="mensajeError" value="Escribe una contraseña de mínimo 8 caracteres."/>
        </c:when>
        <c:when test="${param.rol ne 'ADMINISTRADOR' and param.rol ne 'COORDINACION' and param.rol ne 'DIRECTOR' and param.rol ne 'EVALUADOR' and param.rol ne 'ESTUDIANTE'}">
          <c:set var="mensajeError" value="El rol seleccionado no es válido."/>
        </c:when>
        <c:otherwise>
          <c:catch var="errorBuscarCorreo">
            <sql:query var="correoExistente" dataSource="${db}">
              SELECT id FROM parcial_julian.usuarios WHERE lower(correo)=lower(btrim(CAST(? AS TEXT))) LIMIT 1
              <sql:param value="${fn:trim(param.correo)}"/>
            </sql:query>
          </c:catch>
          <c:choose>
            <c:when test="${not empty errorBuscarCorreo}">
              <c:set var="mensajeError" value="No fue posible comprobar el correo en Supabase. Inténtalo nuevamente."/>
            </c:when>
            <c:when test="${correoExistente.rowCount gt 0}">
              <c:set var="mensajeError" value="Ese correo ya está registrado. Usa Editar para actualizar su contraseña o activar la cuenta."/>
            </c:when>
            <c:otherwise>
              <c:catch var="errorCrearUsuario">
                <sql:update var="filasCreadas" dataSource="${db}">
                  WITH semilla AS MATERIALIZED (SELECT md5(random()::text || clock_timestamp()::text) AS sal)
                  INSERT INTO parcial_julian.usuarios
                    (nombre, correo, rol, programa, sal, clave_hash, identificacion, nivel, plan, creditos, metodologia, activo)
                  SELECT CAST(? AS TEXT),lower(btrim(CAST(? AS TEXT))),CAST(? AS TEXT),CAST(? AS TEXT),
                         semilla.sal,encode(sha256(convert_to(semilla.sal || CAST(? AS TEXT),'UTF8')),'hex'),
                         CAST(? AS TEXT),CAST(? AS TEXT),CAST(? AS TEXT),CAST(? AS SMALLINT),CAST(? AS BOOLEAN),TRUE
                  FROM semilla
                  <sql:param value="${fn:trim(param.nombre)}"/>
                  <sql:param value="${fn:trim(param.correo)}"/>
                  <sql:param value="${param.rol}"/>
                  <sql:param value="${param.programa}"/>
                  <sql:param value="${param.clave}"/>
                  <sql:param value="${param.identificacion}"/>
                  <sql:param value="${param.nivel}"/>
                  <sql:param value="${param.plan}"/>
                  <sql:param value="${empty param.creditos ? '0' : param.creditos}"/>
                  <sql:param value="${param.metodologia eq 'true'}"/>
                </sql:update>
              </c:catch>
              <c:choose>
                <c:when test="${not empty errorCrearUsuario or filasCreadas ne 1}">
                  <c:set var="mensajeError" value="No se pudo registrar la cuenta. Comprueba que el correo no esté duplicado y que los datos sean válidos."/>
                </c:when>
                <c:otherwise>
                  <%-- Confirmación real: valida una consulta con la misma fórmula de login. --%>
                  <c:catch var="errorVerificarUsuario">
                    <sql:query var="cuentaVerificada" dataSource="${db}">
                      SELECT id FROM parcial_julian.usuarios
                      WHERE lower(correo)=lower(btrim(CAST(? AS TEXT)))
                        AND clave_hash=encode(sha256(convert_to(sal || CAST(? AS TEXT),'UTF8')),'hex')
                        AND rol=CAST(? AS TEXT) AND activo=TRUE LIMIT 1
                      <sql:param value="${fn:trim(param.correo)}"/>
                      <sql:param value="${param.clave}"/>
                      <sql:param value="${param.rol}"/>
                    </sql:query>
                  </c:catch>
                  <c:choose>
                    <c:when test="${not empty errorVerificarUsuario or cuentaVerificada.rowCount ne 1}">
                      <c:set var="mensajeError" value="La cuenta se insertó, pero no pasó la prueba de inicio de sesión. En la lista, pulsa Editar y vuelve a establecer la contraseña."/>
                    </c:when>
                    <c:otherwise>
                      <c:catch var="errorAuditoriaCrear">
                        <sql:update dataSource="${db}">
                          INSERT INTO parcial_julian.auditoria(usuario_id,entidad,accion,detalle)
                          VALUES(CAST(? AS BIGINT),'usuarios','crear',CAST(? AS TEXT))
                          <sql:param value="${sessionScope.idUsuario}"/>
                          <sql:param value="${fn:trim(param.correo)}"/>
                        </sql:update>
                      </c:catch>
                      <c:redirect url="/usuarios.jsp?ok=creado"/>
                    </c:otherwise>
                  </c:choose>
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${param.accion eq 'editar' or param.accion eq 'eliminar' or param.accion eq 'cambiar'}">
      <c:catch var="errorOperacion">
        <c:choose>
          <c:when test="${param.accion eq 'editar' and not empty param.id and not empty fn:trim(param.nombre)}">
            <sql:update var="filasGuardadas" dataSource="${db}">
              UPDATE parcial_julian.usuarios SET nombre=CAST(? AS TEXT),rol=CAST(? AS TEXT),programa=CAST(? AS TEXT),identificacion=CAST(? AS TEXT),nivel=CAST(? AS TEXT),plan=CAST(? AS TEXT),creditos=CAST(? AS SMALLINT),metodologia=CAST(? AS BOOLEAN) WHERE id=CAST(? AS BIGINT)
              <sql:param value="${fn:trim(param.nombre)}"/><sql:param value="${param.rol}"/><sql:param value="${param.programa}"/><sql:param value="${param.identificacion}"/><sql:param value="${param.nivel}"/><sql:param value="${param.plan}"/><sql:param value="${empty param.creditos ? '0' : param.creditos}"/><sql:param value="${param.metodologia eq 'true'}"/><sql:param value="${param.id}"/>
            </sql:update>
            <c:if test="${not empty param.clave}">
              <c:choose>
                <c:when test="${fn:length(param.clave) lt 8}">
                  <c:set var="mensajeError" value="La contraseña nueva debe tener al menos 8 caracteres."/>
                </c:when>
                <c:otherwise>
                  <sql:update var="claveActualizada" dataSource="${db}">
                    UPDATE parcial_julian.usuarios SET clave_hash=encode(sha256(convert_to(sal || CAST(? AS TEXT),'UTF8')),'hex') WHERE id=CAST(? AS BIGINT)
                    <sql:param value="${param.clave}"/><sql:param value="${param.id}"/>
                  </sql:update>
                </c:otherwise>
              </c:choose>
            </c:if>
          </c:when>
          <c:when test="${param.accion eq 'eliminar' and param.id ne sessionScope.idUsuario}">
            <sql:update var="filasGuardadas" dataSource="${db}">
              DELETE FROM parcial_julian.usuarios WHERE id=CAST(? AS BIGINT) AND rol != 'ADMINISTRADOR'
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.anteproyectos WHERE estudiante_id=CAST(? AS BIGINT) OR director_id=CAST(? AS BIGINT) OR evaluador_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.revisiones WHERE revisor_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.ideas WHERE creado_por=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.historial WHERE actor_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.documentos WHERE usuario_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.integrantes WHERE estudiante_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.notificaciones WHERE usuario_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.notas_criterios WHERE evaluador_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.decisiones WHERE coordinador_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.versiones WHERE autor_id=CAST(? AS BIGINT))
              AND NOT EXISTS(SELECT 1 FROM parcial_julian.auditoria WHERE usuario_id=CAST(? AS BIGINT))
              <sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/><sql:param value="${param.id}"/>
            </sql:update>
          </c:when>
          <c:when test="${param.accion eq 'cambiar' and param.id ne sessionScope.idUsuario}">
            <sql:update var="filasGuardadas" dataSource="${db}">
              UPDATE parcial_julian.usuarios SET activo=NOT activo WHERE id=CAST(? AS BIGINT)
              <sql:param value="${param.id}"/>
            </sql:update>
          </c:when>
        </c:choose>
      </c:catch>
      <c:choose>
        <c:when test="${not empty errorOperacion}"><c:set var="mensajeError" value="No se pudo completar la operación. Comprueba los datos y que no existan registros vinculados."/></c:when>
        <c:when test="${not empty mensajeError}"><%-- La validación del formulario ya explica el error. --%></c:when>
        <c:when test="${filasGuardadas ne 1}"><c:set var="mensajeError" value="No se modificó ninguna cuenta. Comprueba el usuario seleccionado y las restricciones de eliminación."/></c:when>
        <c:otherwise>
          <c:catch var="errorAuditoria">
            <sql:update dataSource="${db}">
              INSERT INTO parcial_julian.auditoria(usuario_id,entidad,accion,detalle) VALUES(CAST(? AS BIGINT),'usuarios',CAST(? AS TEXT),CAST(? AS TEXT))
              <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${param.accion}"/><sql:param value="${param.id}"/>
            </sql:update>
          </c:catch>
          <c:redirect url="/usuarios.jsp?ok=actualizado"/>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:otherwise><c:set var="mensajeError" value="No se reconoció la operación solicitada."/></c:otherwise>
  </c:choose>
</c:if>
<sql:query var="usuarios" dataSource="${db}">SELECT id,nombre,correo,rol,programa,nivel,activo FROM parcial_julian.usuarios ORDER BY id DESC</sql:query>
<c:if test="${not empty param.editar}"><sql:query var="edicion" dataSource="${db}">SELECT id,nombre,correo,rol,programa,identificacion,nivel,plan,creditos,metodologia FROM parcial_julian.usuarios WHERE id=CAST(? AS BIGINT)<sql:param value="${param.editar}"/></sql:query></c:if>
<c:set var="nombreFormulario" value="${edicion.rows[0].nombre}"/>
<c:set var="correoFormulario" value="${edicion.rows[0].correo}"/>
<c:if test="${pageContext.request.method eq 'POST' and param.accion eq 'crear'}">
  <c:set var="nombreFormulario" value="${param.nombre}"/>
  <c:set var="correoFormulario" value="${param.correo}"/>
</c:if>
<c:set var="titulo" value="Gestión de usuarios"/><c:set var="subtitulo" value="El administrador crea cuentas y define sus permisos."/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<c:if test="${not empty mensajeError}"><div class="alert bad"><c:out value="${mensajeError}"/></div></c:if>
<c:if test="${param.ok eq 'utf8'}"><div class="alert good">Se revisaron y corrigieron las tildes guardadas anteriormente. Los nuevos formularios ya utilizan UTF-8.</div></c:if>
<c:if test="${param.ok eq 'creado'}"><div class="alert good">Usuario creado y contraseña verificada. Ya puede iniciar sesión con el correo y la contraseña asignados.</div></c:if>
<c:if test="${param.ok eq 'actualizado' or param.ok eq '1'}"><div class="alert good">Cambios guardados correctamente.</div></c:if>
<div class="split"><div class="panel"><h2><c:choose><c:when test="${edicion.rowCount gt 0}">Editar cuenta</c:when><c:otherwise>Registrar nuevo usuario</c:otherwise></c:choose></h2>
<form method="post" accept-charset="UTF-8" class="stack"><input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}'/>"><input type="hidden" name="accion" value="${edicion.rowCount gt 0 ? 'editar':'crear'}"><input type="hidden" name="id" value="<c:out value='${edicion.rows[0].id}'/>">
<label>Nombre completo<input name="nombre" required maxlength="160" value="<c:out value='${nombreFormulario}'/>" placeholder="Nombre y apellido"></label>
<label>Correo electrónico<input type="email" name="correo" required maxlength="180" value="<c:out value='${correoFormulario}'/>" <c:if test="${edicion.rowCount gt 0}">readonly</c:if>></label>
<label>Rol<select name="rol" required><c:forTokens items="ADMINISTRADOR,COORDINACION,DIRECTOR,EVALUADOR,ESTUDIANTE" delims="," var="r"><option value="${r}" ${edicion.rowCount gt 0 and edicion.rows[0].rol eq r ? 'selected':''}><c:out value="${r}"/></option></c:forTokens></select></label>
<label>Programa académico<input name="programa" maxlength="150" value="<c:out value='${edicion.rows[0].programa}'/>" placeholder="Ingeniería de Sistemas"></label>
<label>Documento de identidad<input name="identificacion" maxlength="35" value="<c:out value='${edicion.rows[0].identificacion}'/>" placeholder="Identificación"></label>
<label>Nivel de formación<select name="nivel"><option value="">Por definir</option><option value="TECNOLOGICO" ${edicion.rows[0].nivel eq 'TECNOLOGICO'?'selected':''}>Tecnológico</option><option value="PROFESIONAL" ${edicion.rows[0].nivel eq 'PROFESIONAL'?'selected':''}>Profesional</option><option value="TECNICO" ${edicion.rows[0].nivel eq 'TECNICO'?'selected':''}>Técnico</option></select></label>
<label>Tipo de plan<select name="plan"><option value="">Sin registrar</option><option value="ANTERIOR" ${edicion.rows[0].plan eq 'ANTERIOR'?'selected':''}>Anterior al Decreto 1330</option><option value="POSTERIOR" ${edicion.rows[0].plan eq 'POSTERIOR'?'selected':''}>Posterior al Decreto 1330</option></select></label>
<label>Porcentaje de créditos aprobados<input name="creditos" type="number" min="0" max="100" value="${empty edicion.rows[0].creditos?'0':edicion.rows[0].creditos}"/></label>
<label>Metodología académica<select name="metodologia"><option value="false">No registrada</option><option value="true" ${edicion.rows[0].metodologia eq true?'selected':''}>Aprobada</option></select></label>
<label>Contraseña <small><c:if test="${edicion.rowCount gt 0}">(Opcional: deja en blanco para conservarla)</c:if></small><input type="password" name="clave" id="claveUsuario" ${edicion.rowCount gt 0 ? '' : 'required'} minlength="8" autocomplete="new-password" placeholder="Mínimo 8 caracteres"></label>

<label style="display:flex;align-items:center;gap:9px;font-size:.9rem"><input type="checkbox" style="width:auto" onchange="document.querySelectorAll('#claveUsuario').forEach(function(c){c.type=this.checked?'text':'password'}.bind(this))"> Mostrar contraseña</label>
<button class="primary" type="submit">Guardar usuario</button><c:if test="${edicion.rowCount gt 0}"><a class="btn ghost" href="<c:url value='/usuarios.jsp'/>">Cancelar edición</a></c:if></form></div>
<div class="panel"><div class="search-line"><h2>Usuarios registrados</h2><form method="post" accept-charset="UTF-8" style="margin:0;display:inline-block"><input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}'/>"><input type="hidden" name="accion" value="normalizar_utf8"><button type="submit" class="btn small" title="Reparar texto de nombres y programas guardados con codificación incorrecta">Corregir tildes existentes</button></form><label>Buscar<input type="search" data-table-search="usuariosTabla" placeholder="Nombre, correo, rol o programa"/></label></div><div class="table-wrap"><table id="usuariosTabla"><thead><tr><th>Nombre</th><th>Correo</th><th>Rol</th><th>Programa</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>
<c:forEach items="${usuarios.rows}" var="u"><tr><td><strong><c:out value="${u.nombre}"/></strong></td><td><c:out value="${u.correo}"/></td><td><span class="chip"><c:out value="${u.rol}"/></span></td><td><c:out value="${u.programa}"/></td><td><span class="chip ${u.activo ? 'green' : 'gray'}">${u.activo ? 'Activo' : 'Inactivo'}</span></td><td class="actions"><a class="btn small" href="<c:url value='/usuarios.jsp'><c:param name='editar' value='${u.id}'/></c:url>">Editar</a><c:if test="${u.id ne sessionScope.idUsuario}"><form method="post" class="inline" data-confirm="¿Cambiar el estado de este usuario?"><input type="hidden" name="csrf" value="${sessionScope.csrf}"><input type="hidden" name="accion" value="cambiar"><input type="hidden" name="id" value="${u.id}"><button class="btn small danger" type="submit">${u.activo ? 'Desactivar':'Activar'}</button></form><form method="post" class="inline" data-confirm="Eliminará este usuario únicamente si no tiene registros vinculados. ¿Continuar?"><input type="hidden" name="csrf" value="${sessionScope.csrf}"/><input type="hidden" name="accion" value="eliminar"/><input type="hidden" name="id" value="${u.id}"/><button class="btn small danger" type="submit">Eliminar</button></form></c:if></td></tr></c:forEach></tbody></table></div></div></div>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>
