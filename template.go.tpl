type {{ $.InterfaceName }} interface {
{{range .MethodSet}}
	{{.Name}}(context.Context, *{{.Request}}) (*{{.Reply}}, error)
{{end}}
}
func Register{{ $.InterfaceName }}(r gin.IRouter, srv http.Server) {
	s := {{.Name}}{
		server: srv,
		router:     r,
	}
	s.RegisterService()
}

type {{$.Name}} struct {
	server http.Server
	router gin.IRouter
}

{{range .Methods}}
func (s *{{$.Name}}) {{ .HandlerName }} (ctx *gin.Context) {
	var in {{.Request}}
{{if .HasPathParams }}
	if err := ctx.ShouldBindUri(&in); err != nil {
		ctx.Error(err)
		return
	}
{{end}}
{{if eq .Method "GET" "DELETE" }}
	if err := ctx.ShouldBindQuery(&in); err != nil {
		ctx.Error(err)
		return
	}
{{else if eq .Method "POST" "PUT" }}
	if err := ctx.ShouldBindJSON(&in); err != nil {
		ctx.Error(err)
		return
	}
{{else}}
	if err := ctx.ShouldBind(&in); err != nil {
		ctx.Error(err)
		return
	}
{{end}}
	md := metadata.New(nil)
	for k, v := range ctx.Request.Header {
		md.Set(k, v...)
	}
	newCtx := metadata.NewIncomingContext(ctx.Request.Context(), md)
	h := s.server.Middlware(func(ctx context.Context, req interface{}) (interface{}, error) {
		return s.server.({{ $.InterfaceName }}).{{.Name}}(ctx, req.(*{{.Request}}))
	})
	
	out, err := h(newCtx, &in)
	data, code, err := server.HandleResponse(ctx, out, err)
	if err != nil {
		ctx.String(500, "Internal Server Error" + err.Error())
		return
	}
	ctx.String(code, data)
	return
}
{{end}}

func (s *{{$.Name}}) RegisterService() {
{{range .Methods}}
		s.router.Handle("{{.Method}}", "{{.Path}}", s.{{ .HandlerName }})
{{end}}
}