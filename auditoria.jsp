<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${sessionScope.rol ne 'ADMINISTRADOR'}"><c:redirect url="/panel.jsp"/></c:if>
<sql:query var="audStats" dataSource="${db}">SELECT COUNT(*) AS total,COUNT(*) FILTER(WHERE fecha >= CURRENT_DATE-INTERVAL '7 DAYS') AS semana,COUNT(DISTINCT usuario_id) AS responsables FROM parcial_julian.auditoria</sql:query>
<sql:query var="audRegistros" dataSource="${db}">SELECT a.id,a.fecha,a.entidad,a.accion,a.detalle,COALESCE(u.nombre,'Sistema') AS responsable FROM parcial_julian.auditoria a LEFT JOIN parcial_julian.usuarios u ON u.id=a.usuario_id ORDER BY a.fecha DESC,a.id DESC LIMIT 300</sql:query>
<c:set var="titulo" value="Auditoría del sistema"/><c:set var="subtitulo" value="Registro de eventos relevantes y cambios administrativos."/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="audit-summary"><div><span>Eventos registrados</span><strong><c:out value="${audStats.rows[0].total}"/></strong></div><div><span>Últimos 7 días</span><strong><c:out value="${audStats.rows[0].semana}"/></strong></div><div><span>Responsables</span><strong><c:out value="${audStats.rows[0].responsables}"/></strong></div></div>
<section class="panel"><div class="search-line"><div><span class="eyebrow accent">CONTROL Y TRAZABILIDAD</span><h2>Historial de operaciones</h2></div><label>Buscar<input type="search" data-table-search="tablaAuditoria" placeholder="Responsable, módulo u operación" aria-label="Buscar operaciones"></label></div>
<div class="table-wrap"><table id="tablaAuditoria"><thead><tr><th>Fecha</th><th>Responsable</th><th>Módulo</th><th>Operación</th><th>Descripción</th></tr></thead><tbody>
<c:forEach items="${audRegistros.rows}" var="e"><tr><td class="nowrap"><fmt:formatDate value="${e.fecha}" pattern="dd/MM/yyyy HH:mm"/></td><td><strong><c:out value="${e.responsable}"/></strong></td><td><span class="module-tag"><c:out value="${e.entidad}"/></span></td><td><c:out value="${e.accion}"/></td><td class="audit-description"><c:out value="${e.detalle}" default="Operación registrada"/></td></tr></c:forEach>
</tbody></table></div>
<c:if test="${audRegistros.rowCount eq 0}"><div class="empty-audit"><span class="empty-audit-icon">◎</span><h3>Sin cambios registrados todavía</h3><p>Las acciones realizadas desde Usuarios, Ideas, Anteproyectos, Asignaciones, Revisiones, Decisiones y Prácticas aparecerán aquí cuando se guarden.</p></div></c:if>
<p class="inline-note">Se muestran los 300 eventos más recientes. El historial corresponde a operaciones realmente guardadas por el sistema.</p>
</section><%@ include file="/WEB-INF/jspf/pie.jspf" %>
