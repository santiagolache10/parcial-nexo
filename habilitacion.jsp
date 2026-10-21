<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${sessionScope.rol ne 'ESTUDIANTE'}"><c:redirect url="/panel.jsp"/></c:if>

<sql:query var="datos" dataSource="${db}">SELECT nombre,programa,nivel,plan,creditos,metodologia FROM parcial_julian.usuarios WHERE id=CAST(? AS BIGINT)<sql:param value="${sessionScope.idUsuario}"/></sql:query><c:set var="u" value="${datos.rows[0]}"/>
<c:set var="titulo" value="Mi habilitación académica"/><c:set var="subtitulo" value="Consulta informativa de los datos que figuran en el sistema."/><%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<section class="panel"><h2>Estado académico registrado</h2><div class="details-grid"><div><span>Estudiante</span><strong><c:out value="${u.nombre}"/></strong></div><div><span>Programa</span><strong><c:out value="${u.programa}"/></strong></div><div><span>Créditos aprobados</span><strong><c:out value="${u.creditos}"/> %</strong></div><div><span>Metodología</span><strong>${u.metodologia ? 'Registrada':'Pendiente o no registrada'}</strong></div></div>
<c:choose><c:when test="${u.creditos ge 75 and u.metodologia}"><div class="alert good">Los datos registrados cumplen la validación informativa de créditos y metodología.</div></c:when><c:otherwise><div class="alert bad">Hay información o requisitos pendientes de registrar o verificar en Coordinación.</div></c:otherwise></c:choose>
<div class="academic-progress" aria-label="Avance de créditos aprobados">
  <div class="academic-progress-head"><span>Avance registrado de créditos</span><strong><c:out value="${u.creditos}"/> %</strong></div>
  <div class="academic-progress-track"><div class="academic-progress-fill" style="width:<c:out value='${u.creditos}'/>%"></div></div>
  <div class="academic-progress-grid"><span><strong>Programa:</strong> <c:out value="${u.programa}"/></span><span><strong>Nivel:</strong> <c:out value="${u.nivel}" default="Por actualizar"/></span><span><strong>Plan académico:</strong> <c:out value="${u.plan}" default="Por actualizar"/></span></div>
</div></section><%@ include file="/WEB-INF/jspf/pie.jspf" %>
