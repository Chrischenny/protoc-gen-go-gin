type {{ $.InterfaceName }} interface {
{{range .MethodSet}}
	{{.Name}}(context.Context, *{{.Request}}) (*{{.Reply}}, error)
{{end}}
}
func Register{{ $.InterfaceName }}(router *http.Router, server *http.Server, service {{ $.InterfaceName }}) {
	s := {{.Name}}{
		server:  server,
		service: service,
		router: router,
	}
	s.RegisterService()
}

type {{$.Name}} struct {
	router *http.Router
	server *http.Server
	service {{ $.InterfaceName }}
}

{{range .Methods}}
func (s *{{$.Name}}) {{ .HandlerName }} (ctx http.Context) {
	var in {{.Request}}
	if err := ctx.Bind(&in); err != nil {
		ctx.Result(400, nil, err)
		return
	}
	if err := ctx.BindQuery(&in); err != nil {
		ctx.Result(400, nil, err)
		return
	}
	h := s.server.Middlware(func(ctx context.Context, req interface{}) (interface{}, error) {
		return s.service.({{ $.InterfaceName }}).{{.Name}}(ctx, req.(*{{.Request}}))
	})
	
	out, err := h(ctx, &in)
	ctx.Result(200, out, err)
}
{{end}}

func (s *{{$.Name}}) RegisterService() {
{{range .Methods}}
		s.router.Handle("{{.Method}}", "{{.Path}}", s.{{ .HandlerName }})
{{end}}
}