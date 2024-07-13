// global.d.ts
interface Window {
    ReactNativeWebView: {
        postMessage: (message: string) => void;
    };
}
