import gradio as gr
from fasthtml.common import *
from gradio.routes import mount_gradio_app
from monsterui.all import *
from memexplatform.ui.structure import ifhtmx, add_prefix_to_routes
from memexplatform.pluginspec import hookimpl
from memexplatform.ui.external import embed_external_app
# Plugin prefix
prefix = '/gappreload'
gradio_url = prefix+"_gradio" # Note gradio_url can't be prefix/{some path}

def create_app():
    hdrs = Theme.neutral.headers(highlightjs=True)
    gradio_script = Script(
        src="https://gradio.s3-us-west-2.amazonaws.com/5.35.0/gradio.js",
        type="module")
    
    newhdrs = hdrs + [gradio_script]
    app = FastHTML(hdrs=newhdrs, live=True, exts='ws')
    rt = app.route
    return app, rt

app, rt = create_app()

def predict(text):
    return text.upper()

gradio_app = gr.Interface(fn=predict, inputs="text", outputs="text")

# @rt('/')
# def get_external_app():
#     return embed_external_app(url='https://agrilite.app.beast.local', title='Agribot')

@rt('/')
def get_external_app(request):
    return ifhtmx(request, embed_external_app(url=gradio_url, title='Agribot'))

@hookimpl
def mount_apps():
    return (prefix, app, "gradio")

@hookimpl
def get_nav_items():
    nav_dict = {
        "Reload": [
            ("Gradio Demo (Iframe)", "/"),
            # ("Gradio Demo (Embed)", "/embed"),
            # ("Gradio Demo (JS API)", "/js-api"),
            # ("Gradio Demo (Proxy)", "/proxy")
        ]
    }
    return add_prefix_to_routes(nav_dict, prefix)


@hookimpl
def mount_gradio_app():
    """Returns a {prefix:gradio_app} for mounting to host app """
    return {gradio_url : gradio_app}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
